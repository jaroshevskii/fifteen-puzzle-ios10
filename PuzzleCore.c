#include "PuzzleCore.h"
#include <stdlib.h>

void puz_rng_seed(PuzRng *rng, uint64_t seed) {
    rng->state = seed;
}

uint64_t puz_rng_next(PuzRng *rng) {
    uint64_t z = (rng->state += UINT64_C(0x9E3779B97F4A7C15));
    z = (z ^ (z >> 30)) * UINT64_C(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)) * UINT64_C(0x94D049BB133111EB);
    return z ^ (z >> 31);
}

int puz_solved_tiles(int grid, int *out) {
    const int count = grid * grid;
    for (int i = 0; i < count - 1; ++i) out[i] = i + 1;
    out[count - 1] = 0;
    return count;
}

int puz_is_solved(const int *tiles, int grid) {
    const int count = grid * grid;
    for (int i = 0; i < count - 1; ++i) {
        if (tiles[i] != i + 1) return 0;
    }
    return tiles[count - 1] == 0;
}

int puz_empty_index(const int *tiles, int grid) {
    const int count = grid * grid;
    for (int i = 0; i < count; ++i) {
        if (tiles[i] == 0) return i;
    }
    return -1;
}

int puz_is_adjacent(int a, int b, int grid) {
    const int ra = a / grid, ca = a % grid;
    const int rb = b / grid, cb = b % grid;
    return (ra == rb && abs(ca - cb) == 1) || (ca == cb && abs(ra - rb) == 1);
}

int puz_slide(int *tiles, int *history, int *historyLen, int grid, int pos) {
    const int empty = puz_empty_index(tiles, grid);
    const int count = grid * grid;
    if (empty < 0 || pos < 0 || pos >= count || !puz_is_adjacent(pos, empty, grid)) return 0;
    if (*historyLen >= PUZ_MAX_HISTORY) return 0;
    const int tmp = tiles[pos];
    tiles[pos] = tiles[empty];
    tiles[empty] = tmp;
    history[(*historyLen)++] = pos;
    return 1;
}

// Builds a board by applying `count` random legal slides from solved, recording
// the move history (so the board is always solvable and reversible). The pick
// uses a plain modulo of the generator output so it is identical on every
// platform for the same seed (mirroring PuzzleCore::nextIndex).
void puz_scramble(int grid, PuzRng *rng, int *tiles, int *history, int *historyLen, int count) {
    puz_solved_tiles(grid, tiles);
    *historyLen = 0;
    int empty = grid * grid - 1;
    int previous = -1;
    for (int i = 0; i < count; ++i) {
        const int rr = empty / grid, cc = empty % grid;
        int opts[4], n = 0;
        if (rr > 0) opts[n++] = empty - grid;
        if (rr < grid - 1) opts[n++] = empty + grid;
        if (cc > 0) opts[n++] = empty - 1;
        if (cc < grid - 1) opts[n++] = empty + 1;
        int filtered[4], m = 0;
        for (int k = 0; k < n; ++k) {
            if (opts[k] != previous) filtered[m++] = opts[k];
        }
        const int pick = filtered[puz_rng_next(rng) % m];
        tiles[empty] = tiles[pick];
        tiles[pick] = 0;
        history[(*historyLen)++] = pick;
        previous = empty;
        empty = pick;
    }
    if (puz_is_solved(tiles, grid)) {
        const int rr = empty / grid, cc = empty % grid;
        int pick = -1;
        if (rr > 0) pick = empty - grid;
        else if (cc > 0) pick = empty - 1;
        else if (rr < grid - 1) pick = empty + grid;
        else pick = empty + 1;
        if (pick >= 0 && pick < grid * grid) {
            tiles[empty] = tiles[pick];
            tiles[pick] = 0;
            history[(*historyLen)++] = pick;
        }
    }
}