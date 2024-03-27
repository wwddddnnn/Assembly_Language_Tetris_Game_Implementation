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
# The address of the landed tetrominos
ADDR_TETR:
    .word 0x1000b000
    
# - $v0: the service number of 'syscall'
# - $v1:
# - $a0: the argument that is operated by 'syscall'
# - $a1: the color value to draw on the bitmap
# - $a2: the type of the tetromino
# - $a3: the address of landed tetrominos (ADDR_TETR)
# - $t0:
# - $t1:
# - $t2:
# - $t3:
# - $t4:
# - $t5:
# - $t6:
# - $t7:
# - $t8: the total offset of the starting pixel for storing grid/wall
# - $t9: 
# - $s0: the total offsets of the leftest pixel of the tetromino. If more, choose one
# - $s1: the total offsets of the topmost pixel of the tetromino. If more, choose one
# - $s2: the total offsets of the rightest pixel of the tetromino. If more, choose one
# - $s3: the total offsets of the bottom pixel of the tetromino. If more, choose one
# - $s4: the address of bitmap display (ADDR_DSPL)
# - $s5: the address of keyboard (ADDR_KBRD)
# - $s6: the address of grid (ADDR_GRID)
# - $s7: the address of walls (ADDR_WALL)


##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Tetris game.
	
main:
# Initialize the game
lw $s4, ADDR_DSPL       # $s4 = base address for display
lw $s5, ADDR_KBRD       # $s5 = address of keyboard
lw $s6, ADDR_GRID       # $s6 = address of grid
lw $s7, ADDR_WALL       # $s7 = address of walls
lw $a3, ADDR_TETR       # $a3 = address of landed tetrominos

# draw bottom border
addi $t0, $zero, 5      # $t0 = x coordinate of line
addi $t1, $zero, 30     # $t1 = y coordinate of line
addi $t2, $zero, 16     # $t2 = length of line
addi $t3, $zero, 2      # $t3 = height of line
jal draw_rectangle      # call the rectangle-drawing function

# draw left border
addi $t0, $zero, 5      # set x coordinate of line
addi $t1, $zero, 0      # set y coordinate of line
addi $t2, $zero, 1      # set length of line
addi $t3, $zero, 30      # set height of line
jal draw_rectangle        # call the rectangle-drawing function

# draw right border
addi $t0, $zero, 20      # set x coordinate of line
addi $t1, $zero, 0      # set y coordinate of line
addi $t2, $zero, 1      # set length of line
addi $t3, $zero, 30      # set height of line
jal draw_rectangle        # call the rectangle-drawing function

# draw grid
addi $t0, $zero, 6      # set x coordinate of line
addi $t1, $zero, 0      # set y coordinate of line
addi $t2, $zero, 14      # set length of line
addi $t3, $zero, 30      # set height of line
jal draw_grid        # call the rectangle-drawing function

# $t0 is x coordinate, $t1 is y coordinate, $a2 is the type of the tetromino,
addi $t0, $zero, 10      # set x coordinate of line
addi $t1, $zero, 10      # set y coordinate of line
addi $a2, $zero, 'S'      # set length of line
jal draw_tetromino

j SKIP_FUNCTION

# define draw rectangle function, $t0 is x coordinate, $t1 is y coordinate, $t2 is width, $t3 is height
draw_rectangle:
    sll $t4, $t1, 7         # convert vertical offset to pixels (by multiplying $t1 by 128)
    sll $t5, $t3, 7         # convert height of rectangle from pixels to rows of bytes (by multiplying $t3 by 128)
    add $t5, $t4, $t5       # calculate value of $t4 for the last line in the rectangle.
    
outer_top:
    sll $t6, $t0, 2         # convert horizontal offset to pixels (by multiplying $t0 by 4)
    sll $t7, $t2, 2         # convert length of line from pixels to bytes (by multiplying $t2 by 4)
    add $t7, $t6, $t7       # calculate value of $t4 for end of the horizontal line.
    
inner_top:
    add $t9, $t6, $t4           # store the total offset of the starting pixel (relative to $s4)
    add $t8, $s7, $t9           # store the total offset of the starting pixel for storing wall ($s7 + offset)
    add $t9, $s4, $t9           # calculate the location of the starting pixel ($s4 + offset)
    li $a1, 0x00ff00            # $a1 = green
    sw $a1, 0($t9)              # paint the current unit on the first row green
    sw $a1, 0($t8)
    addi $t6, $t6, 4            # move horizontal offset to the right by one pixel
    beq $t6, $t7, inner_end     # break out of the line-drawing loop
    j inner_top                 # jump to the start of the inner loop
    
inner_end:
    addi $t4, $t4, 128          # move vertical offset down by one line
    beq $t4, $t5, outer_end     # on last line, break out of the outer loop
    j outer_top                 # jump to the top of the outer loop
    
outer_end:
    jr $ra                      # return to calling program

# draw background grid,$a0 is x coordinate, $a1 is y coordinate, $a2 is width of the grid, $a3 is height of the grid
draw_grid:
    li $a1, 0x17161A            # $a1 = dark grey

    sll $t4, $t1, 7         # convert vertical offset to pixels (by multiplying $t1 by 256)
    sll $t5, $t3, 7         # convert height of rectangle from pixels to rows of bytes (by multiplying $t3 by 256)
    add $t5, $t4, $t5       # calculate value of $t4 for the last line in the rectangle.
    
outer_top_grid:
    # if previous color is dark grey, change to light grey. If previous color is light grey, change to dark grey.
    beq $a1, 0x17161A, if_out   # check if previoud colour if dark grey 
    li $a1, 0x17161A            # change $a1 to dark grey 
    j end_out
    
if_out:
    li $a1, 0x1b1b1b    # change $a1 to light grey 
    
end_out:
    sll $t6, $t0, 2         # convert horizontal offset to pixels (by multiplying $t0 by 4)
    sll $t7, $t2, 2         # convert length of line from pixels to bytes (by multiplying $t2 by 4)
    add $t7, $t6, $t7       # calculate value of $t6 for end of the horizontal line.
    
inner_top_grid:
    add $t9, $t6, $t4           # store the total offset of the starting pixel (relative to $s4)
    add $t8, $s6, $t9           # calculate the location of the starting pixel for store the grid($s6 + offset)
    add $t9, $s4, $t9           # calculate the location of the starting pixel ($s4 + offset)
    
    # if previous color is dark grey, change to light grey. If previous color is light grey, change to dark grey.
    beq $a1, 0x17161A, if #check if previoud colour if dark grey 
    li $a1, 0x17161A    # change $t4 to dark grey 
    j end
    
if:
    li $a1, 0x1b1b1b    # change $a1 to light grey 
    
end:
    sw $a1, 0($t9)              # paint the current unit on the first row yellow
    sw $a1, 0($t8)              # store the color of the current unit in ADDR_GRID
    
    addi $t6, $t6, 4            # move horizontal offset to the right by one pixel
    beq $t6, $t7, inner_end_grid     # break out of the line-drawing loop
    j inner_top_grid                 # jump to the start of the inner loop
    
inner_end_grid:    
    addi $t4, $t4, 128          # move vertical offset down by one line
    beq $t4, $t5, outer_end_grid     # on last line, break out of the outer loop
    j outer_top_grid                 # jump to the top of the outer loop
    
outer_end_grid:
    
    jr $ra                      # return to calling program

# $a1 is the color value to draw on the bitmap, $a2 is the type of the tetromino, 
draw_tetromino:
    li $a1, 0xff0000        # $a1 = red
    addi $t3, $zero, 52     # the started point is fixed in the middle of the rectangle
    add $t7, $zero, $t3     # store the total offset of the starting pixel for moving the tetromino in the game loop
    add $t3, $s4, $t3       # calculate the location of the starting pixel ($s4 + offset)
    
    # draw shape by $a2
    bne $a2, 'O', I
    sw $a1, 0($t3)
    sw $a1, 4($t3)
    sw $a1, 128($t3)
    sw $a1, 132($t3)
    add $s0, $t7, $zero
    addi $s1, $t7, 4
    addi $s2, $t7, 132
    addi $s3, $t7, 128
    
    addi $a2, $zero, 'I'    # to make the next tetromino be different with the current one.
    j end_tetromino
    
I:
    bne $a2, 'I', S
    sw $a1, 0($t3)
    sw $a1, 128($t3)
    sw $a1, 256($t3)
    sw $a1, 384($t3)
    addi $s0, $t7, 128
    add $s1, $t7, $zero
    addi $s2, $t7, 256
    addi $s3, $t7, 384
    
    addi $a2, $zero, 'S'
    j end_tetromino
    
S:
    bne $a2, 'S', Z
    sw $a1, 0($t3)
    sw $a1, 4($t3)
    sw $a1, 128($t3)
    sw $a1, 124($t3)
    addi $s0, $t7, 124
    add $s1, $t7, $zero
    addi $s2, $t7, 4
    addi $s3, $t7, 128
    
    
    addi $a2, $zero, 'Z'
    j end_tetromino
    
Z:
    bne $a2, 'Z', L
    sw $a1, 0($t3)
    sw $a1, 4($t3)
    sw $a1, 132($t3)
    sw $a1, 136($t3)
    add $s0, $t7, $zero
    addi $s1, $t7, 4
    addi $s2, $t7, 136
    addi $s3, $t7, 132
    
    addi $a2, $zero, 'L'
    j end_tetromino
    
L:
    bne $a2, 'L', J
    sw $a1, 0($t3)
    sw $a1, 128($t3)
    sw $a1, 256($t3)
    sw $a1, 260($t3)
    addi $s0, $t7, 128
    add $s1, $t7, $zero
    addi $s2, $t7, 260
    addi $s3, $t7, 256
    
    addi $a2, $zero, 'J'
    j end_tetromino
    
J:
    bne $a2, 'J', T
    sw $a1, 0($t3)
    sw $a1, 128($t3)
    sw $a1, 256($t3)
    sw $a1, 252($t3)
    addi $s0, $t7, 252
    add $s1, $t7, $zero
    addi $s2, $t7, 128
    addi $s3, $t7, 256
    
    addi $a2, $zero, 'T'
    j end_tetromino
    
T:
    sw $a1, 0($t3)
    sw $a1, 4($t3)
    sw $a1, 132($t3)
    sw $a1, 8($t3)
    add $s0, $t7, $zero
    addi $s1, $t7, 4
    addi $s2, $t7, 8
    addi $s3, $t7, 132
    
    addi $a2, $zero, 'O'
    
end_tetromino:

    
SKIP_FUNCTION:  

game_loop:
	# 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
    lw $t8, 0($s5)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    li 	$v0, 32                     # service number = sleep
	li 	$a0, 1                      # $a0 = the length of time to sleep in milliseconds
	syscall
	addi $t0, $t0, 1
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    beq $t0, 50, gravity            # the gravity: drop 1 pixel for every 0.5 second
    b game_loop
    
gravity:
    add $t0, $zero, $zero
    j respond_to_S

keyboard_input:                     # A key is pressed
    lw $a0, 4($s5)                  # Load second word from keyboard to $a0
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
    # check if it moves against the left wall and landed tetrominoes
    subi $s0, $s0, 4                # calculate the new offset after moving left
    add $t4, $a3, $s0               # calculate the location of the leftest pixel in the ADDR_TETR
    add $t1, $s7, $s0               # calculate the location of the leftest pixel in the ADDR_WALL
    addi $s0, $s0, 4
    lw $t5, 0($t4)                  # load the color of this position in ADDR_TETR
    bne $zero, $t5, game_loop       # if this postion has landed tetrominoes(has color), ignore the pressing.
    lw $t5, 0($t1)                  # load the color of this position in ADDR_WALL
    bne $zero, $t5, game_loop       # if this postion is the wall(has color), ignore the pressing.
    
    add $t1, $s6, $s0               # calculate the location of the leftest pixel in the grid
    lw $t2, 0($t1)                  # load the grid color of this location
    add $t1, $s4, $s0               # calculate the location of the leftest pixel in the bitmap
    sw $t2, 0($t1)                  # draw the grid color on this location in bitmap
    
    add $t1, $s6, $s1               # topmost
    lw $t2, 0($t1)
    add $t1, $s4, $s1
    sw $t2, 0($t1)
    
    add $t1, $s6, $s2               # rightest
    lw $t2, 0($t1)
    add $t1, $s4, $s2
    sw $t2, 0($t1)
    
    add $t1, $s6, $s3               # bottom
    lw $t2, 0($t1)
    add $t1, $s4, $s3
    sw $t2, 0($t1)
    
    subi $s0, $s0, 4                # calculate the new offset after moving left
    add $t1, $s4, $s0               # calculate the location of the leftest pixel in the bitmap
    sw $a1, 0($t1)                  # draw the color on this location in bitmap
    subi $s1, $s1, 4                # topmost
    add $t1, $s4, $s1
    sw $a1, 0($t1)
    subi $s2, $s2, 4                # rightest
    add $t1, $s4, $s2
    sw $a1, 0($t1)
    subi $s3, $s3, 4                # bottom
    add $t1, $s4, $s3
    sw $a1, 0($t1)
	j game_loop

respond_to_S:                       # let the tertromino move down for 1 pixel
    # check if it moves against the bottom wall and the landed tetrominos
    addi $s0, $s0, 128              # calculate the new offset after moving down
    add $t4, $a3, $s0               # calculate the location of the leftest pixel in the ADDR_TETR
    add $t1, $s7, $s0               # calculate the location of the leftest pixel in the ADDR_WALL
    subi $s0, $s0, 128
    lw $t5, 0($t4)                  # load the color of this position in ADDR_TETR
    bne $zero, $t5, land            # # if this postion has landed tetrominoes(has color), the tetromino is landed.
    lw $t5, 0($t1)                  # load the color of this position in ADDR_WALL
    bne $zero, $t5, land            # if this postion is the wall(has color), the tetromino is landed.
    
    addi $s1, $s1, 128              # topmost
    add $t4, $a3, $s1
    add $t1, $s7, $s1
    subi $s1, $s1, 128
    lw $t5, 0($t4)             
    bne $zero, $t5, land
    lw $t5, 0($t1)
    bne $zero, $t5, land
    
    addi $s2, $s2, 128              # rightest
    add $t4, $a3, $s2
    add $t1, $s7, $s2
    subi $s2, $s2, 128
    lw $t5, 0($t4)             
    bne $zero, $t5, land
    lw $t5, 0($t1)
    bne $zero, $t5, land
    
    addi $s3, $s3, 128              # bottom
    add $t4, $a3, $s3
    add $t1, $s7, $s3
    subi $s3, $s3, 128
    lw $t5, 0($t4)             
    bne $zero, $t5, land
    lw $t5, 0($t1)
    bne $zero, $t5, land

    add $t1, $s6, $s0               # calculate the location of the leftest pixel in the grid
    lw $t2, 0($t1)                  # load the grid color of this location
    add $t1, $s4, $s0               # calculate the location of the leftest pixel in the bitmap
    sw $t2, 0($t1)                  # draw the grid color on this location in bitmap
    
    add $t1, $s6, $s1               # topmost
    lw $t2, 0($t1)
    add $t1, $s4, $s1
    sw $t2, 0($t1)
    
    add $t1, $s6, $s2               # rightest
    lw $t2, 0($t1)
    add $t1, $s4, $s2
    sw $t2, 0($t1)
    
    add $t1, $s6, $s3               # bottom
    lw $t2, 0($t1)
    add $t1, $s4, $s3
    sw $t2, 0($t1)
    
    addi $s0, $s0, 128              # calculate the new offset after moving down
    add $t1, $s4, $s0               # calculate the location of the leftest pixel in the bitmap
    sw $a1, 0($t1)                  # draw the color on this location in bitmap
    addi $s1, $s1, 128              # topmost
    add $t1, $s4, $s1
    sw $a1, 0($t1)
    addi $s2, $s2, 128              # rightest
    add $t1, $s4, $s2
    sw $a1, 0($t1)
    addi $s3, $s3, 128              # bottom
    add $t1, $s4, $s3
    sw $a1, 0($t1)
	j game_loop
	
respond_to_D:                       # let the tertromino move right for 1 pixel
    # check if it moves against the right wall
    addi $s2, $s2, 4                # calculate the new offset after moving left
    add $t4, $a3, $s0               # calculate the location of the leftest pixel in the ADDR_TETR
    add $t1, $s7, $s2               # calculate the location of the leftest pixel in the ADDR_WALL
    subi $s2, $s2, 4
    lw $t5, 0($t4)                  # load the color of this position in ADDR_TETR
    bne $zero, $t5, game_loop       # if this postion has landed tetrominoes(has color), ignore the pressing.
    lw $t5, 0($t1)                  # load the color of this position in ADDR_WALL
    bne $zero, $t5, game_loop       # if this postion is the wall(has color), ignore the pressing.
    
    add $t1, $s6, $s0               # calculate the location of the leftest pixel in the grid
    lw $t2, 0($t1)                  # load the grid color of this location
    add $t1, $s4, $s0               # calculate the location of the leftest pixel in the bitmap
    sw $t2, 0($t1)                  # draw the grid color on this location in bitmap
    
    add $t1, $s6, $s1               # topmost
    lw $t2, 0($t1)
    add $t1, $s4, $s1
    sw $t2, 0($t1)
    
    add $t1, $s6, $s2               # rightest
    lw $t2, 0($t1)
    add $t1, $s4, $s2
    sw $t2, 0($t1)
    
    add $t1, $s6, $s3               # bottom
    lw $t2, 0($t1)
    add $t1, $s4, $s3
    sw $t2, 0($t1)
    
    addi $s0, $s0, 4                # calculate the new offset after moving right
    add $t1, $s4, $s0               # calculate the location of the leftest pixel in the bitmap
    sw $a1, 0($t1)                  # draw the color on this location in bitmap
    addi $s1, $s1, 4                # topmost
    add $t1, $s4, $s1
    sw $a1, 0($t1)
    addi $s2, $s2, 4                # rightest
    add $t1, $s4, $s2
    sw $a1, 0($t1)
    addi $s3, $s3, 4                # bottom
    add $t1, $s4, $s3
    sw $a1, 0($t1)
	j game_loop
	
land:
    add $t1, $a3, $s0               # calculate the new location of the leftest pixel in stored landed tetrominos
    sw $a1, 0($t1)
    add $t1, $a3, $s1               # calculate the new location of the topmost pixel in stored landed tetrominos
    sw $a1, 0($t1)
    add $t1, $a3, $s2               # calculate the new location of the rightest pixel in stored landed tetrominos
    sw $a1, 0($t1)
    add $t1, $a3, $s3               # calculate the new location of the bottom pixel in stored landed tetrominos
    sw $a1, 0($t1)
    j draw_tetromino
