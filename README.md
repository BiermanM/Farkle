# Farkle
Farkle, a popular dice game, created entirely in MIPS Assembly. This project was created as the final project for CS 3340.003 (Computer Architecture) at UT Dallas during the Spring 2017 semester.

## Rules
Farkle uses six dice and can be played by two people. The goal of the game is to reach a score of 10,000. For each turn, the player rolls all six dice. All dice that are scored are placed aside. The player can take the current total from that score and add it to their current total or keep rolling at the end of each throw within the player’s turn. If the player scores all six dice, they get to reuse all six dice. If the player cannot score any of the dice on that turn, then they have "farkled" and lose all that they accumulated during that turn.

## Scoring
| Score Type     | Value                                                    |
|:--------------:|:--------------------------------------------------------:|
| One 1          | 100                                                      |
| One 5          | 50                                                       |
| Three 1s       | 1000                                                     |
| Three 2s       | 200                                                      |
| Three 3s       | 300                                                      |
| Three 4s       | 400                                                      |
| Three 5s       | 500                                                      |
| Three 6s       | 600                                                      |
| 4 of a Kind    | Multiply Three of a Kind score by 2                      |
| 5 of a Kind    | Multiply Three of a Kind score by 4                      |
| 6 of a Kind    | Multiply Three of a Kind score by 8                      |
| 3 Pairs        | 1500                                                     |
| Small Straight | 2000 (A small straight is only 1 2 3 4 5, not 2 3 4 5 6) |
| Straight       | 2500                                                     |
