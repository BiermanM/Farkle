# Matthew Bierman
# CS 3340.003
# 11/20/17
# Final Project -- Farkle (Dice Game)


#### print_int ####	print_int(4) or print_int($t0)
.macro print_int(%x)
		li	$v0, 1
		add	$a0, $zero, %x
		syscall
.end_macro
#### print_str ####	print_str("string in quotes")
.macro print_str(%str)
		.data
macro_str:	.asciiz	%str
		.text
		li	$v0, 4
		la	$a0, macro_str
		syscall
.end_macro
		
	.data
p1Total:	.word	0
p2Total:	.word	0
p1TempTotal:	.word	0
p2TempTotal:	.word	0

	.text
# Print main menu text
mainMenu:
	print_str("\n\nWelcome to Farkle! Choose from the following options:\n1) Play!\n2) Rules\n3) Scoring\n> ")
	
	# Get int input from user (selection from menu)
	li	$v0, 5
	syscall
	move	$t0, $v0
	
	# If user enters 1, go to play. If user enters 2, go to rules. If user enters 3, go to scoring. Otherwise, reload current page
	beq	$t0, 1, play
	beq	$t0, 2, rules
	beq	$t0, 3, scoring
	j	mainMenu

# Print rules text
rules:
	print_str("\n\nRules:\nFarkle uses six dice and can be played by two people. The goal of the game is to reach a score of 10,000.\n\nFor each turn, the player rolls all six dice. All dice that are scored are placed aside. The player can\ntake the current total from that score and add it to their current total or keep rolling at the end of\neach throw within the player’s turn. If the player scores all six dice, they get to reuse all six dice.\nIf the player cannot score any of the dice on that turn, then they have “farkled” and lose all that they\naccumulated during that turn.\n\nPress 0 to return to the main menu\n> ")
	
	# Get int input from user (to return to main menu)
	li	$v0, 5
	syscall
	move	$t0, $v0
	
	# Return to main menu if user entered 0, otherwise, reload current page
	beq	$t0, 0, mainMenu
	j	rules

# Print scoring text
scoring:
	print_str("\n\nScoring:\nOne 1           100\nOne 5           50\nThree 1s        1000\nThree 2s        200\nThree 3s        300\nThree 4s        400\nThree 5s        500\nThree 6s        600\n4 of a Kind     Multiply Three of a Kind score by 2\n5 of a Kind     Multiply Four of a Kind score by 2\n6 of a Kind     Multiply Five of a Kind score by 2\n3 Pairs         1500\nSmall Straight  2000 (A small straight is only 1 2 3 4 5, not 2 3 4 5 6)\nStraight        2500\n\nPress 0 to return to the main menu\n> ")
	
	# Get int input from user (to return to main menu)
	li	$v0, 5
	syscall
	move	$t0, $v0
	
	# Return to main menu if user entered 0, otherwise, reload current page
	beq	$t0, 0, mainMenu
	j	scoring

# Print beginning of game text and create seed for random number generation
play:
	print_str("\n\nLet's play Farkle!\n\n")
	
	# create random number seed
	li	$v0, 30		# get time in milliseconds (as a 64-bit value)
	syscall
	move	$t0, $a0	# save the lower 32-bits of time
	# seed the random generator (just once)
	li	$a0, 1		# random generator id (will be used later)
	move 	$a1, $t0	# seed from time
	li	$v0, 40		# seed random number generator syscall
	syscall

# Set total scores for players, check if a player has won, and set variables
player1StartTurn:
	# Since player 1 always goes after player 2, add player 2's subtotal score to their total score if they didn't farkle
	lw	$s0, p2TempTotal
	lw	$s1, p2Total
	add	$s1, $s1, $s0
	sw	$s1, p2Total
	add	$s0, $zero, $zero
	sw	$s0, p2TempTotal
	lw	$s1, p1TempTotal
	add	$s1, $zero, $zero
	sw	$s1, p1TempTotal

	# Load player's total scores
	lw	$t1, p1Total
	lw	$t2, p2Total

	# Print text for player 1
	print_str("Player 1's score is ")
	print_int($t1)
	print_str(", Player 2's score is ")
	print_int($t2)
	
	# Check if either player has won yet
	jal	checkForP1Win
	
	print_str("\nIt's Player 1's turn!\n")
	
	# Start Player 1's first roll
	li	$t0, 6		# $t0 = total number of dice remaining
	li	$t1, 0		# $t1 = number of dice used during that roll
	li	$t8, 0		# $t8 = subtotal score from turn

# Roll dice, determine points for roll, and continue/exit menu for Player 1
player1TurnLoop:
	# No dice rolled yet
	li	$t1, 0
	
	# Roll six dice
	li	$t2, 0		# set counter for getRoll to 0
	jal	getRoll	
	
	li	$t2, 0		# $t2 = number of occurrences of 1
	li	$t3, 0		# $t3 = number of occurrences of 2
	li	$t4, 0		# $t4 = number of occurrences of 3
	li	$t5, 0		# $t5 = number of occurrences of 4
	li	$t6, 0		# $t6 = number of occurrences of 5
	li	$t7, 0		# $t7 = number of occurrences of 6
	
	# count the number of occurrences for 1-6 on each dice rolled
	jal	count1Dice
	
	# Print roll result
	print_str("\tRoll: ")
	jal	print1Dice
	
	# Get the score for that roll
	jal	getScore
	move	$t8, $v0
	move	$t1, $v1
	
	print_str(" -- ")
	print_int($t8)
	print_str(" points")
	
	# If no score from roll, then player farkled
	beq	$t8, 0, farkledP1
	
	# Change total dice remaining by removing scored dice from current roll
	sub	$t0, $t0, $t1
	
	# If all dice are used, player can roll again will all 6 dice again
	beq	$t0, 0, rollWithAllDiceP1
	
	print_str("\n\t1) Roll again with ")
	print_int($t0)
	print_str(" dice")
	lw	$t9, p1TempTotal
	add	$t9, $t9, $t8
	print_str("\n\t2) Keep points and end turn (")
	print_int($t9)
	print_str(" points total)\n\t> ")
	
	# Get int input from user (selection from menu)
	li	$v0, 5
	syscall
	move	$s0, $v0
	
	print_str("\n")
	
	sw	$t9, p1TempTotal
	
	# If user enters 1, roll again. If user enters 2, end turn and switch to Player 2's turn. Otherwise, exit program.
	beq	$s0, 1, player1TurnLoop
	beq	$s0, 2, player2StartTurn
	
	j	exit

# Set total scores for players, check if a player has won, and set variables
player2StartTurn:
	# Since Player 2 always goes after Player 1, add Player 1's subtotal score to their total score if they didn't farkle
	lw	$s0, p1TempTotal
	lw	$s1, p1Total
	add	$s1, $s1, $s0
	sw	$s1, p1Total
	add	$s0, $zero, $zero
	sw	$s0, p1TempTotal
	lw	$s1, p2TempTotal
	add	$s1, $zero, $zero
	sw	$s1, p2TempTotal
	
	lw	$t1, p1Total
	lw	$t2, p2Total
	
	# Print text for player 1
	print_str("Player 1's score is ")
	print_int($t1)
	print_str(", Player 2's score is ")
	print_int($t2)
	
	# Check if either player has won yet
	jal	checkForP1Win
	
	print_str("\nIt's Player 2's turn!\n")
	
	# Start Player 2's first roll
	li	$t0, 6		# $t0 = total number of dice remaining
	li	$t1, 0		# $t1 = number of dice used during that roll
	li	$t8, 0		# $t8 = subtotal score from turn

# Roll dice, determine points for roll, and continue/exit menu for Player 2
player2TurnLoop:
	# No dice rolled yet
	li	$t1, 0
	
	# Roll six dice
	li	$t2, 0		# set counter for getRoll to 0
	jal	getRoll	
	
	li	$t2, 0		# $t2 = number of occurrences of 1
	li	$t3, 0		# $t3 = number of occurrences of 2
	li	$t4, 0		# $t4 = number of occurrences of 3
	li	$t5, 0		# $t5 = number of occurrences of 4
	li	$t6, 0		# $t6 = number of occurrences of 5
	li	$t7, 0		# $t7 = number of occurrences of 6
	
	# count the number of occurrences for 1-6 on each dice rolled
	jal	count1Dice
	
	# Print roll result
	print_str("\tRoll: ")
	jal	print1Dice
	
	# Get the score for that roll
	jal	getScore
	move	$t8, $v0
	move	$t1, $v1
	
	print_str(" -- ")
	print_int($t8)
	print_str(" points")
	
	# If no score from roll, then player farkled
	beq	$t8, 0, farkledP2
	
	# Change total dice remaining by removing scored dice from current roll
	sub	$t0, $t0, $t1
	
	# If all dice are used, player can roll again will all 6 dice again
	beq	$t0, 0, rollWithAllDiceP2
	
	print_str("\n\t1) Roll again with ")
	print_int($t0)
	print_str(" dice")
	lw	$t9, p2TempTotal
	add	$t9, $t9, $t8
	print_str("\n\t2) Keep points and end turn (")
	print_int($t9)
	print_str(" points total)\n\t> ")
	
	# Get int input from user (selection from menu)
	li	$v0, 5
	syscall
	move	$s0, $v0
	
	print_str("\n")
	
	sw	$t9, p2TempTotal
	
	# If user enters 1, roll again. If user enters 2, end turn and switch to Player 2's turn. Otherwise, exit program.
	beq	$s0, 1, player2TurnLoop
	beq	$s0, 2, player1StartTurn
	
	j	exit

# If Player 1 farkles, zero out both players' subtotal and start Player 2's turn
farkledP1:
	print_str("\n\tUh oh, you farkled!\n\n")
	sw	$0, p1TempTotal
	sw	$0, p2TempTotal
	j	player2StartTurn

# If Player 2 farkles, zero out both players' subtotal and start Player 1's turn
farkledP2:
	print_str("\n\tUh oh, you farkled!\n\n")
	sw	$0, p1TempTotal
	sw	$0, p2TempTotal
	j	player1StartTurn

# Check if Player 1 has won (10,000+ points)
checkForP1Win:
	blt	$t1, $t2, checkForP2Win
	blt	$t1, 10000, checkForP2Win
	print_str("\nPlayer 1 wins!")
	
	j	exit
# Check if Player 2 has won (10,000+ points)
checkForP2Win:
	blt	$t2, $t1, endCheckForWin
	blt	$t2, 10000, endCheckForWin
	print_str("\nPlayer 2 wins!")
	
	j	exit
endCheckForWin:
	jr	$ra
	
# Allow Player 1 to roll with 6 dice if all 6 dice can be scored
rollWithAllDiceP1:
	addi	$t0, $t0, 6
	
	print_str("\n\t1) Roll again with ")
	print_int($t0)
	print_str(" dice")
	lw	$t9, p1TempTotal
	add	$t9, $t9, $t8
	print_str("\n\t2) Keep points and end turn (")
	print_int($t9)
	print_str(" points total)\n\t> ")
	
	# Get int input from user (selection from menu)
	li	$v0, 5
	syscall
	move	$s0, $v0
	
	print_str("\n")
	
	sw	$t9, p1TempTotal
	
	# If user enters 1, roll again. If user enters 2, end turn and switch to Player 2's turn. Otherwise, exit program.
	beq	$s0, 1, player1TurnLoop
	beq	$s0, 2, player2StartTurn
	
	j	exit

# Allow Player 2 to roll with 6 dice if all 6 dice can be scored
rollWithAllDiceP2:
	addi	$t0, $t0, 6
	
	print_str("\n\t1) Roll again with ")
	print_int($t0)
	print_str(" dice")
	lw	$t9, p2TempTotal
	add	$t9, $t9, $t8
	print_str("\n\t2) Keep points and end turn (")
	print_int($t9)
	print_str(" points total)\n\t> ")
	
	# Get int input from user (selection from menu)
	li	$v0, 5
	syscall
	move	$s0, $v0
	
	print_str("\n")
	
	sw	$t9, p2TempTotal
	
	# If user enters 1, roll again. If user enters 2, end turn and switch to Player 2's turn. Otherwise, exit program.
	beq	$s0, 1, player2TurnLoop
	beq	$s0, 2, player1StartTurn
	
	j	exit

# Roll six dice and store in stack
getRoll:
	# break loop 
	bge	$t2, 24, finishRoll

	# "roll a dice" by getting a random number between 1 and 6
	li	$a0, 0		# load the random number seed
	li	$a1, 5		# get a random number between 0 and 5
	li	$v0, 42
	syscall
	addi	$a0, $a0, 1	# add one to the random number to make the range 1 to 6

	# add roll result to the stack
	move	$t3, $a0
	sub	$sp, $sp, 4
	sw	$t3, 0($sp)
	
	# increase counter by 4 and loop
	addi	$t2, $t2, 4
	j	getRoll
	
finishRoll:
	# return to player's turn
	jr	$ra

# If all 6 dice are used, don't count. Otherwise, count for one dice.
count1Dice:
	blt	$t0, 1, finishOccurrenceCount
	lw	$a0, 0($sp)
# Count the number of occurrences of 1s in Dice #1
countDice1OccurrencesOne:
	bne 	$a0, 1, countDice1OccurrencesTwo
	addi	$t2, $t2, 1
# Count the number of occurrences of 2s in Dice #1
countDice1OccurrencesTwo:
	bne 	$a0, 2, countDice1OccurrencesThree
	addi	$t3, $t3, 1
# Count the number of occurrences of 3s in Dice #1
countDice1OccurrencesThree:
	bne 	$a0, 3, countDice1OccurrencesFour
	addi	$t4, $t4, 1
# Count the number of occurrences of 4s in Dice #1
countDice1OccurrencesFour:
	bne 	$a0, 4, countDice1OccurrencesFive
	addi	$t5, $t5, 1
# Count the number of occurrences of 5s in Dice #1
countDice1OccurrencesFive:
	bne 	$a0, 5, countDice1OccurrencesSix
	addi	$t6, $t6, 1
# Count the number of occurrences of 6s in Dice #1
countDice1OccurrencesSix:
	bne 	$a0, 6, count2Dice
	addi	$t7, $t7, 1

# If 5 dice are used, stop counting. Otherwise, count for a second dice.
count2Dice:
	blt	$t0, 2, finishOccurrenceCount
	lw	$a0, 4($sp)
# Count the number of occurrences of 1s in Dice #2
countDice2OccurrencesOne:
	bne 	$a0, 1, countDice2OccurrencesTwo
	addi	$t2, $t2, 1
# Count the number of occurrences of 2s in Dice #2
countDice2OccurrencesTwo:
	bne 	$a0, 2, countDice2OccurrencesThree
	addi	$t3, $t3, 1
# Count the number of occurrences of 3s in Dice #2
countDice2OccurrencesThree:
	bne 	$a0, 3, countDice2OccurrencesFour
	addi	$t4, $t4, 1
# Count the number of occurrences of 4s in Dice #2
countDice2OccurrencesFour:
	bne 	$a0, 4, countDice2OccurrencesFive
	addi	$t5, $t5, 1
# Count the number of occurrences of 5s in Dice #2
countDice2OccurrencesFive:
	bne 	$a0, 5, countDice2OccurrencesSix
	addi	$t6, $t6, 1
# Count the number of occurrences of 6s in Dice #2
countDice2OccurrencesSix:
	bne 	$a0, 6, count3Dice
	addi	$t7, $t7, 1

# If 4 dice are used, stop counting. Otherwise, count for a third dice.
count3Dice:
	blt	$t0, 3, finishOccurrenceCount
	lw	$a0, 8($sp)
# Count the number of occurrences of 1s in Dice #3
countDice3OccurrencesOne:
	bne 	$a0, 1, countDice3OccurrencesTwo
	addi	$t2, $t2, 1
# Count the number of occurrences of 2s in Dice #3
countDice3OccurrencesTwo:
	bne 	$a0, 2, countDice3OccurrencesThree
	addi	$t3, $t3, 1
# Count the number of occurrences of 3s in Dice #3
countDice3OccurrencesThree:
	bne 	$a0, 3, countDice3OccurrencesFour
	addi	$t4, $t4, 1
# Count the number of occurrences of 4s in Dice #3
countDice3OccurrencesFour:
	bne 	$a0, 4, countDice3OccurrencesFive
	addi	$t5, $t5, 1
# Count the number of occurrences of 5s in Dice #3
countDice3OccurrencesFive:
	bne 	$a0, 5, countDice3OccurrencesSix
	addi	$t6, $t6, 1
# Count the number of occurrences of 6s in Dice #3
countDice3OccurrencesSix:
	bne 	$a0, 6, count4Dice
	addi	$t7, $t7, 1

# If 3 dice are used, stop counting. Otherwise, count for a fourth dice.
count4Dice:
	blt	$t0, 4, finishOccurrenceCount
	lw	$a0, 12($sp)
# Count the number of occurrences of 1s in Dice #4
countDice4OccurrencesOne:
	bne 	$a0, 1, countDice4OccurrencesTwo
	addi	$t2, $t2, 1
# Count the number of occurrences of 2s in Dice #4
countDice4OccurrencesTwo:
	bne 	$a0, 2, countDice4OccurrencesThree
	addi	$t3, $t3, 1
# Count the number of occurrences of 3s in Dice #4
countDice4OccurrencesThree:
	bne 	$a0, 3, countDice4OccurrencesFour
	addi	$t4, $t4, 1
# Count the number of occurrences of 4s in Dice #4
countDice4OccurrencesFour:
	bne 	$a0, 4, countDice4OccurrencesFive
	addi	$t5, $t5, 1
# Count the number of occurrences of 5s in Dice #4
countDice4OccurrencesFive:
	bne 	$a0, 5, countDice4OccurrencesSix
	addi	$t6, $t6, 1
# Count the number of occurrences of 6s in Dice #4
countDice4OccurrencesSix:
	bne 	$a0, 6, count5Dice
	addi	$t7, $t7, 1
	
# If 2 dice are used, stop counting. Otherwise, count for a fifth dice.
count5Dice:
	blt	$t0, 5, finishOccurrenceCount
	lw	$a0, 16($sp)
# Count the number of occurrences of 1s in Dice #5
countDice5OccurrencesOne:
	bne 	$a0, 1, countDice5OccurrencesTwo
	addi	$t2, $t2, 1
# Count the number of occurrences of 2s in Dice #5
countDice5OccurrencesTwo:
	bne 	$a0, 2, countDice5OccurrencesThree
	addi	$t3, $t3, 1
# Count the number of occurrences of 3s in Dice #5
countDice5OccurrencesThree:
	bne 	$a0, 3, countDice5OccurrencesFour
	addi	$t4, $t4, 1
# Count the number of occurrences of 4s in Dice #5
countDice5OccurrencesFour:
	bne 	$a0, 4, countDice5OccurrencesFive
	addi	$t5, $t5, 1
# Count the number of occurrences of 5s in Dice #5
countDice5OccurrencesFive:
	bne 	$a0, 5, countDice5OccurrencesSix
	addi	$t6, $t6, 1
# Count the number of occurrences of 6s in Dice #5
countDice5OccurrencesSix:
	bne 	$a0, 6, count6Dice
	addi	$t7, $t7, 1
	
# If 1 dice is used, stop counting. Otherwise, count for a sixth dice.
count6Dice:
	blt	$t0, 6, finishOccurrenceCount
	lw	$a0, 20($sp)
# Count the number of occurrences of 1s in Dice #6
countDice6OccurrencesOne:
	bne 	$a0, 1, countDice6OccurrencesTwo
	addi	$t2, $t2, 1
# Count the number of occurrences of 2s in Dice #6
countDice6OccurrencesTwo:
	bne 	$a0, 2, countDice6OccurrencesThree
	addi	$t3, $t3, 1
# Count the number of occurrences of 3s in Dice #6
countDice6OccurrencesThree:
	bne 	$a0, 3, countDice6OccurrencesFour
	addi	$t4, $t4, 1
# Count the number of occurrences of 4s in Dice #6
countDice6OccurrencesFour:
	bne 	$a0, 4, countDice6OccurrencesFive
	addi	$t5, $t5, 1
# Count the number of occurrences of 5s in Dice #6
countDice6OccurrencesFive:
	bne 	$a0, 5, countDice6OccurrencesSix
	addi	$t6, $t6, 1
# Count the number of occurrences of 6s in Dice #6
countDice6OccurrencesSix:
	bne 	$a0, 6, finishOccurrenceCount
	addi	$t7, $t7, 1
	
finishOccurrenceCount:
	# return to player's turn
	jr	$ra
	
# If all 6 dice are used, don't print. Otherwise, print for one dice.
print1Dice:
	blt	$t0, 1, finishPrinting
	lw	$s0, 0($sp)
	print_int($s0)
# If 5 dice are used, stop printing. Otherwise, print for a second dice.
print2Dice:
	blt	$t0, 2, finishPrinting
	print_str(" ")
	lw	$s0, 4($sp)
	print_int($s0)
# If 4 dice are used, stop printing. Otherwise, print for a third dice.
print3Dice:
	blt	$t0, 3, finishPrinting
	print_str(" ")
	lw	$s0, 8($sp)
	print_int($s0)
# If 3 dice are used, stop printing. Otherwise, print for a fourth dice.
print4Dice:
	blt	$t0, 4, finishPrinting
	print_str(" ")
	lw	$s0, 12($sp)
	print_int($s0)
# If 2 dice are used, stop printing. Otherwise, print for a fifth dice.
print5Dice:
	blt	$t0, 5, finishPrinting
	print_str(" ")
	lw	$s0, 16($sp)
	print_int($s0)
# If 1 dice are used, stop printing. Otherwise, print for a sixth dice.
print6Dice:
	blt	$t0, 6, finishPrinting
	print_str(" ")
	lw	$s0, 20($sp)
	print_int($s0)

finishPrinting:
	jr	$ra
	
getScore:
	li	$v0, 0		# $v0 = subtotal score
	li	$v1, 0		# $v1 = number of dice used
# Straight -- 1 2 3 4 5 6 (in any order) -- 2500 points
checkStraight:
	# if all 1-6 have exactly one occurrence, set subtotal to 2500 and exit
	bne	$t2, 1, checkSmallStraightOpt1
	bne	$t3, 1, checkSmallStraightOpt1
	bne	$t4, 1, checkSmallStraightOpt1
	bne	$t5, 1, checkSmallStraightOpt1
	bne	$t6, 1, checkSmallStraightOpt1
	bne	$t7, 1, checkSmallStraightOpt1
	addi	$v0, $v0, 2500
	addi	$v1, $v1, 6
	j	exitGetScore
# Small Straight -- 1 2 3 4 5 * (in any order, * = any number, where * isn't a 6)
checkSmallStraightOpt1:		#	Option 1: 1 2 3 4 5 1	-- 	2000 + 100 points
	# if two occurrences of 1, one occurrence each of 2-5, and no occurrences of 6, set subtotal to 2100 and exit
	bne	$t2, 2, checkSmallStraightOpt2
	bne	$t3, 1, checkSmallStraightOpt2
	bne	$t4, 1, checkSmallStraightOpt2
	bne	$t5, 1, checkSmallStraightOpt2
	bne	$t6, 1, checkSmallStraightOpt2
	bne	$t7, 0, checkSmallStraightOpt2
	addi	$v0, $v0, 2100
	addi	$v1, $v1, 6
	j	exitGetScore
checkSmallStraightOpt2:		#	Option 2: 1 2 3 4 5 5	-- 	2000 + 50 points
	# if one occurrence each of 1-4, two occurrences of 5, and no occurrences of 6, set subtotal to 2050 and exit
	bne	$t2, 1, checkSmallStraightOpt3
	bne	$t3, 1, checkSmallStraightOpt3
	bne	$t4, 1, checkSmallStraightOpt3
	bne	$t5, 1, checkSmallStraightOpt3
	bne	$t6, 2, checkSmallStraightOpt3
	bne	$t7, 0, checkSmallStraightOpt3
	addi	$v0, $v0, 2050
	addi	$v1, $v1, 6
	j	exitGetScore
checkSmallStraightOpt3:		#	Option 3: 1 2 3 4 5 *	-- 	2000 points
	# if one occurrence each of 1 & 5, one or two occurrences of 2-4, and no occurrences of 6, set subtotal to 2000 and exit
	bne	$t2, 1, threePairsOpt1
	blt	$t3, 1, threePairsOpt1
	blt	$t4, 1, threePairsOpt1
	blt	$t5, 1, threePairsOpt1
	bne	$t6, 1, threePairsOpt1
	bne	$t7, 0, threePairsOpt1
	addi	$v1, $v1, 5
	addi	$v0, $v0, 2000
	j	exitGetScore
# 3 Pairs -- 1500 points
threePairsOpt1:		#	Option 1:  1 1 2 2 3 3
	bne	$t2, 2, threePairsOpt6
	bne	$t3, 2, threePairsOpt4
	bne	$t4, 2, threePairsOpt2
	j	threePairs
threePairsOpt2:		#	Option 2:  1 1 2 2 4 4 or 1 1 3 3 5 5
	bne	$t5, 2, threePairsOpt3
	j	threePairs
threePairsOpt3:		#	Option 3:  1 1 2 2 5 5
	bne	$t6, 2, threePairsEndsIn6
	j	threePairs
threePairsOpt4:		#	Option 5:  1 1 3 3 4 4
	bne	$t4, 2, threePairsOpt5
	bne	$t5, 2, threePairsOpt2
	j	threePairs
threePairsOpt5:		#	Option 8:  1 1 4 4 5 5
	bne	$t5, 2, threePairsEndsIn6
	bne	$t6, 2, threePairsEndsIn6
	j	threePairs
threePairsOpt6:	#	Option 11: 2 2 3 3 4 4
	bne	$t3, 2, threePairsOpt9
	bne	$t4, 2, threePairsOpt8
	bne	$t5, 2, threePairsOpt7
	j	threePairs
threePairsOpt7:	#	Option 12: 2 2 3 3 5 5
	bne	$t4, 2, threePairsOpt8
	bne	$t6, 2, threePairsEndsIn6
	j	threePairs
threePairsOpt8:	#	Option 14: 2 2 4 4 5 5
	bne	$t5, 2, threePairsEndsIn6
	bne	$t6, 2, threePairsEndsIn6
	j	threePairs
threePairsOpt9:	#	Option 17: 3 3 4 4 5 5
	bne	$t4, 2, threePairsEndsIn6
	bne	$t5, 2, threePairsEndsIn6
	bne	$t6, 2, threePairsEndsIn6
	j	threePairs
threePairsEndsIn6:	#	Ends in 6: 1 1 2 2 6 6, 1 1 3 3 6 6, 1 1 4 4 6 6, 1 1 5 5 6 6, 2 2 3 3 6 6, 2 2 4 4 6 6, 2 2 5 5 6 6, 3 3 4 4 6 6, 3 3 5 5 6 6, 4 4 5 5 6 6
	bne	$t7, 2, sixOfAKindAllOne
	j	threePairs
threePairs:
	addi	$v0, $v0, 1500
	addi	$v1, $v1, 6
	j	exitGetScore
# 6 of a Kind
sixOfAKindAllOne:	#	Option 1: 1 1 1 1 1 1 -- 8000 points
	bne	$t2, 6, sixOfAKindAllTwo
	addi	$v0, $v0, 8000
	addi	$v1, $v1, 6
	j	exitGetScore
sixOfAKindAllTwo:	#	Option 2: 2 2 2 2 2 2 -- 1600 points
	bne	$t3, 6, sixOfAKindAllThree
	addi	$v0, $v0, 1600
	addi	$v1, $v1, 6
	j	exitGetScore
sixOfAKindAllThree:	#	Option 3: 3 3 3 3 3 3 -- 2400 points
	bne	$t4, 6, sixOfAKindAllFour
	addi	$v0, $v0, 2400
	addi	$v1, $v1, 6
	j	exitGetScore
sixOfAKindAllFour:	#	Option 4: 4 4 4 4 4 4 -- 3200 points
	bne	$t5, 6, sixOfAKindAllFive
	addi	$v0, $v0, 3200
	addi	$v1, $v1, 6
	j	exitGetScore
sixOfAKindAllFive:	#	Option 5: 5 5 5 5 5 5 -- 4000 points
	bne	$t6, 6, sixOfAKindAllSix
	addi	$v0, $v0, 4000
	addi	$v1, $v1, 6
	j	exitGetScore
sixOfAKindAllSix:	#	Option 6: 6 6 6 6 6 6 -- 4800 points
	bne	$t7, 6, fiveOfAKindAllOne
	addi	$v0, $v0, 4800
	addi	$v1, $v1, 6
	j	exitGetScore
# 5 of a Kind -- e.g. 1 1 1 1 1 * or 3 3 3 3 3 * (in any order, * = any number)
fiveOfAKindAllOne:	#	Option 1: 1 1 1 1 1 * -- 4000 points
	bne	$t2, 5, fiveOfAKindAllTwo
	addi	$v0, $v0, 4000
	addi	$v1, $v1, 5
	j	one5s
fiveOfAKindAllTwo:	#	Option 2: 2 2 2 2 2 * -- 800 points
	bne	$t3, 5, fiveOfAKindAllThree
	addi	$v0, $v0, 800
	addi	$v1, $v1, 5
	j	one1s
fiveOfAKindAllThree:	#	Option 3: 3 3 3 3 3 * -- 1200 points
	bne	$t4, 5, fiveOfAKindAllFour
	addi	$v0, $v0, 1200
	addi	$v1, $v1, 5
	j	one1s
fiveOfAKindAllFour:	#	Option 4: 4 4 4 4 4 * -- 1600 points
	bne	$t5, 5, fiveOfAKindAllFive
	addi	$v0, $v0, 1600
	addi	$v1, $v1, 5
	j	one1s
fiveOfAKindAllFive:	#	Option 5: 5 5 5 5 5 * -- 2000 points
	bne	$t6, 5, fiveOfAKindAllSix
	addi	$v0, $v0, 2000
	addi	$v1, $v1, 5
	j	one1s
fiveOfAKindAllSix:	#	Option 6: 6 6 6 6 6 * -- 2400 points
	bne	$t7, 5, fourOfAKindAllOne
	addi	$v0, $v0, 2400
	addi	$v1, $v1, 5
	j	one1s
# Check if last dice when rolling 5 of a Kind is a 1
one1s:
	bne	$t2, 1, one5s
	addi	$v0, $v0, 100
	addi	$v1, $v1, 1
	j	exitGetScore
# Check if last dice when rolling 5 of a Kind is a 5
one5s:
	bne	$t6, 1, exitGetScore
	addi	$v0, $v0, 50
	addi	$v1, $v1, 1
	j	exitGetScore
# 4 of a Kind -- e.g. 5 5 5 5 * * or 6 6 6 6 * * (* = any number, where two *'s are different numbers)
fourOfAKindAllOne:	#	Option 1: 1 1 1 1 * * -- 2000 points
	bne	$t2, 4, fourOfAKindAllTwo
	addi	$v0, $v0, 2000
	addi	$v1, $v1, 4
	j	two5s
fourOfAKindAllTwo:	#	Option 2: 2 2 2 2 * * -- 400 points
	bne	$t3, 4, fourOfAKindAllThree
	addi	$v0, $v0, 400
	addi	$v1, $v1, 4
	j	two1s
fourOfAKindAllThree:	#	Option 3: 3 3 3 3 * * -- 600 points
	bne	$t4, 4, fourOfAKindAllFour
	addi	$v0, $v0, 600
	addi	$v1, $v1, 4
	j	two1s
fourOfAKindAllFour:	#	Option 4: 4 4 4 4 * * -- 800 points
	bne	$t5, 4, fourOfAKindAllFive
	addi	$v0, $v0, 800
	addi	$v1, $v1, 4
	j	two1s
fourOfAKindAllFive:	#	Option 5: 5 5 5 5 * * -- 1000 points
	bne	$t6, 4, fourOfAKindAllSix
	addi	$v0, $v0, 1000
	addi	$v1, $v1, 4
	j	two1s
fourOfAKindAllSix:	#	Option 6: 6 6 6 6 * * -- 1200 points
	bne	$t7, 4, threeOfAKindAllOne
	addi	$v0, $v0, 1200
	addi	$v1, $v1, 4
	j	two1s
# Check for two (or less) 1s in a 3 of a Kind or 4 of a Kind
two1s:
	beq	$t2, 0, two5s
	bge	$t2, 3, two5s
	addi	$v0, $v0, 100
	addi	$v1, $v1, 1
	beq	$t2, 1, two5s
	addi	$v0, $v0, 100
	addi	$v1, $v1, 1
	j	exitGetScore
# Check for two (or less) 5s in a 3 of a Kind or 4 of a Kind
two5s:
	beq	$t6, 0, exitGetScore
	bge	$t6, 3, exitGetScore
	addi	$v0, $v0, 50
	addi	$v1, $v1, 1
	beq	$t6, 1, exitGetScore
	addi	$v0, $v0, 50
	addi	$v1, $v1, 1
	j	exitGetScore
# 3 of a Kind -- e.g. 1 1 1 * * * or 4 4 4 * * * (* = any number, where three *'s aren't the 3 of a Kind number)
threeOfAKindAllOne:	#	Option 1: 1 1 1 * * * -- 1000 points
	bne	$t2, 3, threeOfAKindAllTwo
	addi	$v0, $v0, 1000
	addi	$v1, $v1, 3
threeOfAKindAllTwo:	#	Option 2: 2 2 2 * * * -- 200 points
	bne	$t3, 3, threeOfAKindAllThree
	addi	$v0, $v0, 200
	addi	$v1, $v1, 3
threeOfAKindAllThree:	#	Option 3: 3 3 3 * * * -- 300 points
	bne	$t4, 3, threeOfAKindAllFour
	addi	$v0, $v0, 300
	addi	$v1, $v1, 3
threeOfAKindAllFour:	#	Option 4: 4 4 4 * * * -- 400 points
	bne	$t5, 3, threeOfAKindAllFive
	addi	$v0, $v0, 400
	addi	$v1, $v1, 3
threeOfAKindAllFive:	#	Option 5: 5 5 5 * * * -- 500 points
	bne	$t6, 3, threeOfAKindAllSix
	addi	$v0, $v0, 500
	addi	$v1, $v1, 3
threeOfAKindAllSix:	#	Option 6: 6 6 6 * * * -- 600 points
	bne	$t7, 3, ifThreeOfAKind
	addi	$v0, $v0, 600
	addi	$v1, $v1, 3
ifThreeOfAKind:
	beq	$v1, 6, exitGetScore	# If there's two 3 of a Kinds, exit, otherwise, check the remaining 3 dice if they contain 1s or 5s
	beq	$v1, 3, two1s		# If there's only one 3 of a Kind, check for only two 1s or 5s
# Check for two (or less) 1s in a roll that doesn't contain a special score
all1s:
	beq	$t2, 0, two5s
	addi	$v0, $v0, 100
	addi	$v1, $v1, 1
	beq	$t2, 1, two5s
	addi	$v0, $v0, 100
	addi	$v1, $v1, 1
# Check for two (or less) 5s in a roll that doesn't contain a special score
all5s:
	beq	$t6, 0, exitGetScore
	addi	$v0, $v0, 50
	addi	$v1, $v1, 1
	beq	$t6, 1, exitGetScore
	addi	$v0, $v0, 50
	addi	$v1, $v1, 1
	j	exitGetScore
	
exitGetScore:
	jr	$ra

# Exit the program
exit:
	li	$v0, 10
	syscall
