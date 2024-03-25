################ CSC258H1F Winter 2024 Assembly Final Project ##################
# This file contains our implementation of Tetris.
#
# Student 1: Wenzhu Ye, 1005714247
# Student 2: Dongnuo Wu, 1009614794
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       1    
# - Unit height in pixels:      1
# - Display width in pixels:    32
# - Display height in pixels:   32
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
# The address of the grid.
ADDR_GRID:
    .word 0x10009000
# The address of the three walls of the playing area.
ADDR_WALL:
    .word 0x1000a000

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Tetris game.
	
# The Mutable Data for main(draw_rectangle): 
# - $a0: the x coordinate of the starting point for this line.
# - $a1: the y coordinate of the starting point for this line.
# - $a2: the length of this line, measured in pixels
# - $a3: the height of this line, measured in pixels
# - $t0: the base address for display
# - $t1: 
# - $t2: 
# - $t3: 
# - $t4: the colour value to draw on the bitmap
# - $t5: 
# - $t6: 
# - $t7: the grid address
# - $t8: the total offset of the starting pixel for storing grid/wall
# - $t9: the walls address
	
main:
# Initialize the game
lw $t0, ADDR_DSPL # $t0 = base address for display
lw $t9, ADDR_WALL

# draw bottom border
addi $a0, $zero, 5      # set x coordinate of line
addi $a1, $zero, 30      # set y coordinate of line
addi $a2, $zero, 16      # set length of line
addi $a3, $zero, 2      # set height of line
jal draw_rectangle        # call the rectangle-drawing function

# draw left border
addi $a0, $zero, 5      # set x coordinate of line
addi $a1, $zero, 0      # set y coordinate of line
addi $a2, $zero, 1      # set length of line
addi $a3, $zero, 30      # set height of line
jal draw_rectangle        # call the rectangle-drawing function

# draw right border
addi $a0, $zero, 20      # set x coordinate of line
addi $a1, $zero, 0      # set y coordinate of line
addi $a2, $zero, 1      # set length of line
addi $a3, $zero, 30      # set height of line
jal draw_rectangle        # call the rectangle-drawing function

# draw grid
lw $t7, ADDR_GRID
addi $a0, $zero, 6      # set x coordinate of line
addi $a1, $zero, 0      # set y coordinate of line
addi $a2, $zero, 14      # set length of line
addi $a3, $zero, 30      # set height of line
jal draw_grid        # call the rectangle-drawing function

# $a0 is x coordinate, $a1 is y coordinate, $a2 is the type of the tetromino,
addi $a0, $zero, 10      # set x coordinate of line
addi $a1, $zero, 10      # set y coordinate of line
addi $a2, $zero, 'S'      # set length of line
jal draw_tetromino

j SKIP_FUNCTION

# define draw rectangle function, $a0 is x coordinate, $a1 is y coordinate, $a2 is width, $a3 is height
draw_rectangle:
    sll $t2, $a1, 7         # convert vertical offset to pixels (by multiplying $a1 by 128)
    sll $t6, $a3, 7         # convert height of rectangle from pixels to rows of bytes (by multiplying $a3 by 128)
    add $t6, $t2, $t6       # calculate value of $t2 for the last line in the rectangle.
    
outer_top:
    sll $t1, $a0, 2         # convert horizontal offset to pixels (by multiplying $a0 by 4)
    sll $t5, $a2, 2         # convert length of line from pixels to bytes (by multiplying $a2 by 4)
    add $t5, $t1, $t5       # calculate value of $t1 for end of the horizontal line.
    
inner_top:
    add $t3, $t1, $t2           # store the total offset of the starting pixel (relative to $t0)
    add $t8, $t9, $t3           # store the total offset of the starting pixel for storing wall ($t9 + offset)
    add $t3, $t0, $t3           # calculate the location of the starting pixel ($t0 + offset)
    li $t4, 0x00ff00            # $t4 = green
    sw $t4, 0($t3)              # paint the current unit on the first row yellow
    sw $t4, 0($t8)
    addi $t1, $t1, 4            # move horizontal offset to the right by one pixel
    beq $t1, $t5, inner_end     # break out of the line-drawing loop
    j inner_top                 # jump to the start of the inner loop
    
inner_end:
    
    addi $t2, $t2, 128          # move vertical offset down by one line
    beq $t2, $t6, outer_end     # on last line, break out of the outer loop
    j outer_top                 # jump to the top of the outer loop
    
outer_end:
    
    jr $ra                      # return to calling program

# draw background grid,$a0 is x coordinate, $a1 is y coordinate, $a2 is width of the grid, $a3 is height of the grid
draw_grid:
    li $t4, 0x17161A            # $t4 = dark grey

    sll $t2, $a1, 7         # convert vertical offset to pixels (by multiplying $a1 by 256)
    sll $t6, $a3, 7         # convert height of rectangle from pixels to rows of bytes (by multiplying $a3 by 256)
    add $t6, $t2, $t6       # calculate value of $t2 for the last line in the rectangle.
    
outer_top_grid:
    # if previous color is dark grey, change to light grey. If previous color is light grey, change to dark grey.
    beq $t4, 0x17161A, if_out #check if previoud colour if dark grey 
    li $t4, 0x17161A    # change $t4 to dark grey 
    j end_out
    
if_out:
    li $t4, 0x1b1b1b    # change $t4 to light grey 
    
end_out:
    sll $t1, $a0, 2         # convert horizontal offset to pixels (by multiplying $a0 by 4)
    sll $t5, $a2, 2         # convert length of line from pixels to bytes (by multiplying $a2 by 4)
    add $t5, $t1, $t5       # calculate value of $t1 for end of the horizontal line.
    
inner_top_grid:
    add $t3, $t1, $t2           # store the total offset of the starting pixel (relative to $t0)
    add $t8, $t7, $t3           # calculate the location of the starting pixel for store the grid($t7 + offset)
    add $t3, $t0, $t3           # calculate the location of the starting pixel ($t0 + offset)
    
    # if previous color is dark grey, change to light grey. If previous color is light grey, change to dark grey.
    beq $t4, 0x17161A, if #check if previoud colour if dark grey 
    li $t4, 0x17161A    # change $t4 to dark grey 
    j end
    
if:
    li $t4, 0x1b1b1b    # change $t4 to light grey 
    
end:
    sw $t4, 0($t3)              # paint the current unit on the first row yellow
    sw $t4, 0($t8)              # store the color of the current unit in ADDR_GRID
    
    addi $t1, $t1, 4            # move horizontal offset to the right by one pixel
    beq $t1, $t5, inner_end_grid     # break out of the line-drawing loop
    j inner_top_grid                 # jump to the start of the inner loop
    
inner_end_grid:    
    addi $t2, $t2, 128          # move vertical offset down by one line
    beq $t2, $t6, outer_end_grid     # on last line, break out of the outer loop
    j outer_top_grid                 # jump to the top of the outer loop
    
outer_end_grid:
    
    jr $ra                      # return to calling program



# The Mutable Data for draw_tetromio: 
# - $a0: the x coordinate.
# - $a1: the y coordinate.
# - $a2: the type of the temromino
# - $a3: ?
# - $t0: the base address for display
# - $t1: 
# - $t2: 
# - $t3: the starting point?
# - $t4: the colour value to draw on the bitmap (red)
# - $t5: 
# - $t6:
# - $t7: the offset of the starting pixel
# - $s0: the total offsets of the leftest pixel of the tetromino. If more, choose one
# - $s1: the total offsets of the topmost pixel of the tetromino. If more, choose one
# - $s2: the total offsets of the rightest pixel of the tetromino. If more, choose one
# - $s3: the total offsets of the bottom pixel of the tetromino. If more, choose one


# $a0 is x coordinate, $a1 is y coordinate, $a2 is the type of the tetromino,
draw_tetromino:
    li $t4, 0xff0000            # $t4 = red

    sll $t2, $a1, 7         # convert vertical offset to pixels (by multiplying $a1 by 128)
    sll $t6, $a3, 7         # convert height of rectangle from pixels to rows of bytes (by multiplying $a3 by 128)
    add $t6, $t2, $t6       # calculate value of $t2 for the last line in the rectangle.
    sll $t1, $a0, 2         # convert horizontal offset to pixels (by multiplying $a0 by 4)
    sll $t5, $a2, 2         # convert length of line from pixels to bytes (by multiplying $a2 by 4)
    add $t5, $t1, $t5       # calculate value of $t1 for end of the horizontal line.
    add $t3, $t1, $t2       # store the total offset of the starting pixel (relative to $t0)
    add $t7, $zero, $t3     # store the total offset of the starting pixel for moving the tetromino in the game loop
    add $t3, $t0, $t3       # calculate the location of the starting pixel ($t0 + offset)
    
    # draw shape by $a2
    bne $a2, 'O', I
    sw $t4, 0($t3)
    sw $t4, 4($t3)
    sw $t4, 128($t3)
    sw $t4, 132($t3)
    add $s0, $t7, $zero
    addi $s1, $t7, 4
    addi $s2, $t7, 132
    addi $s3, $t7, 128
    j end_tetromino
    
I:
    bne $a2, 'I', S
    sw $t4, 0($t3)
    sw $t4, 128($t3)
    sw $t4, 256($t3)
    sw $t4, 384($t3)
    addi $s0, $t7, 128
    add $s1, $t7, $zero
    addi $s2, $t7, 256
    addi $s3, $t7, 384
    
    j end_tetromino
    
S:
    bne $a2, 'S', Z
    sw $t4, 0($t3)
    sw $t4, 4($t3)
    sw $t4, 128($t3)
    sw $t4, 124($t3)
    addi $s0, $t7, 124
    add $s1, $t7, $zero
    addi $s2, $t7, 4
    addi $s3, $t7, 128
    j end_tetromino
    
Z:
    bne $a2, 'Z', L
    sw $t4, 0($t3)
    sw $t4, 4($t3)
    sw $t4, 132($t3)
    sw $t4, 136($t3)
    add $s0, $t7, $zero
    addi $s1, $t7, 4
    addi $s2, $t7, 136
    addi $s3, $t7, 132 
    j end_tetromino
    
L:
    bne $a2, 'L', J
    sw $t4, 0($t3)
    sw $t4, 128($t3)
    sw $t4, 256($t3)
    sw $t4, 260($t3)
    addi $s0, $t7, 128
    add $s1, $t7, $zero
    addi $s2, $t7, 260
    addi $s3, $t7, 256
    j end_tetromino
    
J:
    bne $a2, 'J', T
    sw $t4, 0($t3)
    sw $t4, 128($t3)
    sw $t4, 256($t3)
    sw $t4, 252($t3)
    addi $s0, $t7, 252
    add $s1, $t7, $zero
    addi $s2, $t7, 128
    addi $s3, $t7, 256 
    j end_tetromino
    
T:
    sw $t4, 0($t3)
    sw $t4, 4($t3)
    sw $t4, 132($t3)
    sw $t4, 8($t3)
    add $s0, $t7, $zero
    addi $s1, $t7, 4
    addi $s2, $t7, 8
    addi $s3, $t7, 132 
    
end_tetromino:

    
SKIP_FUNCTION:  


# The Mutable Data for game_loop(keyboard):
# - $a0: the value that is going to print by 'syscall'.
# - $a2: the type of the tetromino.
# - $t0: the base address for keyboard
# - $t1: the location of the specific pixel in grid
# - $t2: the color of the specific pixel in grid
# - $t3: the location of the specific pixel in bitmap display
# - $t4: the colour value to draw on the bitmap (red)
# - $t6: the base address for display
# - $t7: the grid address 
# - $t8: the first word for keyboard (1 for some keys are pressed, 0 for no key is pressed)
# - $t9: the wall address
# - $v0: the service number for 'syscall'
# - $s0: the total offsets of the leftest pixel of the tetromino. If more, choose one
# - $s1: the total offsets of the topmost pixel of the tetromino. If more, choose one
# - $s2: the total offsets of the rightest pixel of the tetromino. If more, choose one
# - $s3: the total offsets of the bottom pixel of the tetromino. If more, choose one
# - $S4: the total time of sleeping

game_loop:
	# 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1

    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t7, ADDR_GRID
    lw $t6, ADDR_DSPL
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    li 	$v0, 32                     # service number = sleep
	li 	$a0, 1                      # $a0 = the length of time to sleep in milliseconds
	syscall
	addi $s4, $s4, 1
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    beq $s4, 50, gravity            # the gravity: drop 1 pixel for every 0.5 second
    b game_loop
    
gravity:
    add $s4, $zero, $zero
    j respond_to_S

keyboard_input:                     # A key is pressed
    lw $a0, 4($t0)                  # Load second word from keyboard
    beq $a0, 0x71, respond_to_Q     # Check if the key Q was pressed
    beq $a0, 0x77, respond_to_W     # Check if the key W was pressed
    beq $a0, 0x61, respond_to_A     # Check if the key A was pressed
    beq $a0, 0x73, respond_to_S     # Check if the key S was pressed
    beq $a0, 0x64, respond_to_D     # Check if the key D was pressed

    b game_loop

respond_to_Q:
	li $v0, 10                      # Quit gracefully
	syscall

respond_to_W:
	li $v0, 1                      # ask system to print $a0 = 77
	syscall
	j game_loop

respond_to_A:                       # let the tertromino move left for 1 pixel
    # check if it moves against the left wall
    subi $s0, $s0, 4                # calculate the new offset after moving left
    add $t3, $t9, $s0               # calculate the location of the leftest pixel in the ADDR_WALL
    addi $s0, $s0, 4
    lw $t5, 0($t3)                  # load the color of this position in ADDR_WALL
    bne $zero, $t5, game_loop       # if this postion is the wall(has color), ignore the pressing.
    
    add $t1, $t7, $s0               # calculate the location of the leftest pixel in the grid
    lw $t2, 0($t1)                  # load the grid color of this location
    add $t3, $t6, $s0               # calculate the location of the leftest pixel in the bitmap
    sw $t2, 0($t3)                  # draw the grid color on this location in bitmap
    
    add $t1, $t7, $s1               # topmost
    lw $t2, 0($t1)
    add $t3, $t6, $s1
    sw $t2, 0($t3)
    
    add $t1, $t7, $s2               # rightest
    lw $t2, 0($t1)
    add $t3, $t6, $s2
    sw $t2, 0($t3)
    
    add $t1, $t7, $s3               # bottom
    lw $t2, 0($t1)
    add $t3, $t6, $s3
    sw $t2, 0($t3)
    
    subi $s0, $s0, 4                # calculate the new offset after moving left
    add $t3, $t6, $s0               # calculate the location of the leftest pixel in the bitmap
    sw $t4, 0($t3)                  # draw the color on this location in bitmap
    subi $s1, $s1, 4                # topmost
    add $t3, $t6, $s1
    sw $t4, 0($t3)
    subi $s2, $s2, 4                # rightest
    add $t3, $t6, $s2
    sw $t4, 0($t3)
    subi $s3, $s3, 4                # bottom
    add $t3, $t6, $s3
    sw $t4, 0($t3)
	j game_loop

respond_to_S:                       # let the tertromino move down for 1 pixel
    # check if it moves against the bottom wall
    addi $s3, $s3, 128              # calculate the new offset after moving left
    add $t3, $t9, $s3               # calculate the location of the leftest pixel in the ADDR_WALL
    subi $s3, $s3, 128
    lw $t5, 0($t3)                  # load the color of this position in ADDR_WALL
    bne $zero, $t5, game_loop       # if this postion is the wall(has color), ignore the pressing.

    add $t1, $t7, $s0               # calculate the location of the leftest pixel in the grid
    lw $t2, 0($t1)                  # load the grid color of this location
    add $t3, $t6, $s0               # calculate the location of the leftest pixel in the bitmap
    sw $t2, 0($t3)                  # draw the grid color on this location in bitmap
    
    add $t1, $t7, $s1               # topmost
    lw $t2, 0($t1)
    add $t3, $t6, $s1
    sw $t2, 0($t3)
    
    add $t1, $t7, $s2               # rightest
    lw $t2, 0($t1)
    add $t3, $t6, $s2
    sw $t2, 0($t3)
    
    add $t1, $t7, $s3               # bottom
    lw $t2, 0($t1)
    add $t3, $t6, $s3
    sw $t2, 0($t3)
    
    addi $s0, $s0, 128              # calculate the new offset after moving down
    add $t3, $t6, $s0               # calculate the location of the leftest pixel in the bitmap
    sw $t4, 0($t3)                  # draw the color on this location in bitmap
    addi $s1, $s1, 128              # topmost
    add $t3, $t6, $s1
    sw $t4, 0($t3)
    addi $s2, $s2, 128              # rightest
    add $t3, $t6, $s2
    sw $t4, 0($t3)
    addi $s3, $s3, 128              # bottom
    add $t3, $t6, $s3
    sw $t4, 0($t3)
	j game_loop
	
respond_to_D:                       # let the tertromino move right for 1 pixel
    # check if it moves against the right wall
    addi $s2, $s2, 4                # calculate the new offset after moving left
    add $t3, $t9, $s2               # calculate the location of the leftest pixel in the ADDR_WALL
    subi $s2, $s2, 4
    lw $t5, 0($t3)                  # load the color of this position in ADDR_WALL
    bne $zero, $t5, game_loop       # if this postion is the wall(has color), ignore the pressing.
    
    add $t1, $t7, $s0               # calculate the location of the leftest pixel in the grid
    lw $t2, 0($t1)                  # load the grid color of this location
    add $t3, $t6, $s0               # calculate the location of the leftest pixel in the bitmap
    sw $t2, 0($t3)                  # draw the grid color on this location in bitmap
    
    add $t1, $t7, $s1               # topmost
    lw $t2, 0($t1)
    add $t3, $t6, $s1
    sw $t2, 0($t3)
    
    add $t1, $t7, $s2               # rightest
    lw $t2, 0($t1)
    add $t3, $t6, $s2
    sw $t2, 0($t3)
    
    add $t1, $t7, $s3               # bottom
    lw $t2, 0($t1)
    add $t3, $t6, $s3
    sw $t2, 0($t3)
    
    addi $s0, $s0, 4                # calculate the new offset after moving right
    add $t3, $t6, $s0               # calculate the location of the leftest pixel in the bitmap
    sw $t4, 0($t3)                  # draw the color on this location in bitmap
    addi $s1, $s1, 4                # topmost
    add $t3, $t6, $s1
    sw $t4, 0($t3)
    addi $s2, $s2, 4                # rightest
    add $t3, $t6, $s2
    sw $t4, 0($t3)
    addi $s3, $s3, 4                # bottom
    add $t3, $t6, $s3
    sw $t4, 0($t3)
	j game_loop
