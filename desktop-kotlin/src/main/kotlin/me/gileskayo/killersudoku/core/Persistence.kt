package me.gileskayo.killersudoku.core

import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File

/** Cross-platform app-data directory, following each OS's own convention rather than a single
 * flat default -- not much extra code, and it means this app behaves like a normal citizen on
 * each platform instead of dumping a dotfile in the home directory everywhere. */
internal fun appDataDirectory(): File {
    val home = System.getProperty("user.home")
    val os = System.getProperty("os.name").lowercase()
    val dir = when {
        "mac" in os -> File(home, "Library/Application Support/KillerSudoku")
        "win" in os -> File(System.getenv("APPDATA") ?: home, "KillerSudoku")
        else -> File(home, ".config/killersudoku")
    }
    dir.mkdirs()
    return dir
}

private val json = Json { ignoreUnknownKeys = true; prettyPrint = false }

@Serializable
private data class SavedPuzzleData(val board: Board, val difficultyRawValue: Int?)

/** The single in-progress puzzle, persisted locally as one JSON file rather than a database --
 * there's only ever one active puzzle at a time, so a database is more machinery than this
 * needs. Undo/redo history is never part of what's saved (Board's own Transient fields already
 * exclude it), so a restored board always starts with a clean history. */
object PuzzleStore {
    private val file = File(appDataDirectory(), "saved-puzzle.json")

    fun load(): Pair<Board, Difficulty?>? {
        if (!file.exists()) return null
        return try {
            val data = json.decodeFromString<SavedPuzzleData>(file.readText())
            data.board to data.difficultyRawValue?.let { Difficulty.fromRawValue(it) }
        } catch (e: Exception) {
            // A corrupted or outdated-format file shouldn't crash launch -- the player just
            // loses their saved puzzle for this run instead of being locked out entirely.
            null
        }
    }

    fun save(board: Board, difficulty: Difficulty?) {
        file.writeText(json.encodeToString<SavedPuzzleData>(SavedPuzzleData(board, difficulty?.rawValue)))
    }
}

@Serializable
data class SolveRecord(val difficultyRawValue: Int, val elapsedSeconds: Double, val completedAtEpochSeconds: Long) {
    val difficulty: Difficulty get() = Difficulty.fromRawValue(difficultyRawValue) ?: Difficulty.EASY
}

/** Records and queries completed solves, one per difficulty tier -- best time and solve history,
 * stored as one JSON array rather than a database for the same reason [PuzzleStore] does. */
object StatsStore {
    private val file = File(appDataDirectory(), "solve-records.json")

    private fun loadAll(): List<SolveRecord> {
        if (!file.exists()) return emptyList()
        return try {
            json.decodeFromString(file.readText())
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun saveAll(records: List<SolveRecord>) {
        file.writeText(json.encodeToString<List<SolveRecord>>(records))
    }

    fun record(difficulty: Difficulty, elapsedSeconds: Double, completedAtEpochSeconds: Long = System.currentTimeMillis() / 1000) {
        saveAll(loadAll() + SolveRecord(difficulty.rawValue, elapsedSeconds, completedAtEpochSeconds))
    }

    fun bestTime(difficulty: Difficulty): Double? =
        loadAll().filter { it.difficultyRawValue == difficulty.rawValue }.minOfOrNull { it.elapsedSeconds }

    fun solveCount(difficulty: Difficulty): Int =
        loadAll().count { it.difficultyRawValue == difficulty.rawValue }

    fun history(difficulty: Difficulty): List<SolveRecord> =
        loadAll().filter { it.difficultyRawValue == difficulty.rawValue }.sortedByDescending { it.completedAtEpochSeconds }
}
