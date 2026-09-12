#ifndef FIFTEEN_PUZZLE_CORE_H
#define FIFTEEN_PUZZLE_CORE_H

#include <stdint.h>

#define PUZ_MIN_GRID 4
#define PUZ_MAX_GRID 13
#define PUZ_MAX_TILES (PUZ_MAX_GRID * PUZ_MAX_GRID)
#define PUZ_MAX_HISTORY 2048

typedef struct {
    uint64_t state;
} PuzRng;

void puz_rng_seed(PuzRng *rng, uint64_t seed);
uint64_t puz_rng_next(PuzRng *rng);

int puz_solved_tiles(int grid, int *out);
int puz_is_solved(const int *tiles, int grid);
int puz_empty_index(const int *tiles, int grid);
int puz_is_adjacent(int a, int b, int grid);
int puz_slide(int *tiles, int *history, int *historyLen, int grid, int pos);
void puz_scramble(int grid, PuzRng *rng, int *tiles, int *history, int *historyLen, int count);

#endif