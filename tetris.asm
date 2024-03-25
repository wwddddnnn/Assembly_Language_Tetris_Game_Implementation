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
lw $t0, ADDR_DSPL # $t0 = base address for display

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
addi $a0, $zero, 6      # set x coordinate of line
addi $a1, $zero, 0      # set y coordinate of line
addi $a2, $zero, 14      # set length of line
addi $a3, $zero, 30      # set height of line
jal draw_grid        # call the rectangle-drawing function

# $a0 is x coordinate, $a1 is y coordinate, $a2 is the type of the tetromino,
addi $a0, $zero, 10      # set x coordinate of line
addi $a1, $zero, 10      # set y coordinate of line
addi $a2, $zero, 'T'      # set length of line
jal draw_tetromino

j SKIP_FUNCTION

# define draw rectangle function, $a0 is x coordinate, $a1 is y coordinate, $a2 is width, $a3 is height
draw_rectangle:
    sll $t2, $a1, 7         # convert vertical offset to pixels (by multiplying $a1 by 256)
    sll $t6, $a3, 7         # convert height of rectangle from pixels to rows of bytes (by multiplying $a3 by 256)
    add $t6, $t2, $t6       # calculate value of $t2 for the last line in the rectangle.
    outer_top:
    sll $t1, $a0, 2         # convert horizontal offset to pixels (by multiplying $a0 by 4)
    sll $t5, $a2, 2         # convert length of line from pixels to bytes (by multiplying $a2 by 4)
    add $t5, $t1, $t5       # calculate value of $t1 for end of the horizontal line.
    
    inner_top:
    add $t3, $t1, $t2           # store the total offset of the starting pixel (relative to $t0)
    add $t3, $t0, $t3           # calculate the location of the starting pixel ($t0 + offset)
    li $t4, 0x00ff00            # $t4 = green
    sw $t4, 0($t3)              # paint the current unit on the first row yellow
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
    add $t3, $t0, $t3           # calculate the location of the starting pixel ($t0 + offset)
    
    # if previous color is dark grey, change to light grey. If previous color is light grey, change to dark grey.
    beq $t4, 0x17161A, if #check if previoud colour if dark grey 
    li $t4, 0x17161A    # change $t4 to dark grey 
    j end
    if:
    li $t4, 0x1b1b1b    # change $t4 to light grey 
    end:
    sw $t4, 0($t3)              # paint the current unit on the first row yellow
    addi $t1, $t1, 4            # move horizontal offset to the right by one pixel
    beq $t1, $t5, inner_end_grid     # break out of the line-drawing loop
    j inner_top_grid                 # jump to the start of the inner loop
    inner_end_grid:
    
    addi $t2, $t2, 128          # move vertical offset down by one line
    beq $t2, $t6, outer_end_grid     # on last line, break out of the outer loop
    j outer_top_grid                 # jump to the top of the outer loop
    outer_end_grid:
    
    jr $ra                      # return to calling program

# $a0 is x coordinate, $a1 is y coordinate, $a2 is the type of the tetromino,
draw_tetromino:
    li $t4, 0xff0000            # $t4 = red

    sll $t2, $a1, 7         # convert vertical offset to pixels (by multiplying $a1 by 256)
    sll $t6, $a3, 7         # convert height of rectangle from pixels to rows of bytes (by multiplying $a3 by 256)
    add $t6, $t2, $t6       # calculate value of $t2 for the last line in the rectangle.
    sll $t1, $a0, 2         # convert horizontal offset to pixels (by multiplying $a0 by 4)
    sll $t5, $a2, 2         # convert length of line from pixels to bytes (by multiplying $a2 by 4)
    add $t5, $t1, $t5       # calculate value of $t1 for end of the horizontal line.
    add $t3, $t1, $t2           # store the total offset of the starting pixel (relative to $t0)
    add $t3, $t0, $t3           # calculate the location of the starting pixel ($t0 + offset)
    
    # draw shape by $a2
    bne $a2, 'O', I
    sw $t4, 0($t3)
    sw $t4, 4($t3)
    sw $t4, 128($t3)
    sw $t4, 132($t3) 
    j end_tetromino
    I:
    bne $a2, 'I', S
    sw $t4, 0($t3)
    sw $t4, 128($t3)
    sw $t4, 256($t3)
    sw $t4, 384($t3) 
    j end_tetromino
    S:
    bne $a2, 'S', Z
    sw $t4, 0($t3)
    sw $t4, 4($t3)
    sw $t4, 128($t3)
    sw $t4, 124($t3) 
    j end_tetromino
    Z:
    bne $a2, 'Z', L
    sw $t4, 0($t3)
    sw $t4, 4($t3)
    sw $t4, 132($t3)
    sw $t4, 136($t3) 
    j end_tetromino
    L:
    bne $a2, 'L', J
    sw $t4, 0($t3)
    sw $t4, 128($t3)
    sw $t4, 256($t3)
    sw $t4, 240($t3) 
    j end_tetromino
    J:
    bne $a2, 'J', T
    sw $t4, 0($t3)
    sw $t4, 128($t3)
    sw $t4, 256($t3)
    sw $t4, 252($t3) 
    j end_tetromino
    T:
    sw $t4, 0($t3)
    sw $t4, 4($t3)
    sw $t4, 132($t3)
    sw $t4, 8($t3) 
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
    b game_loop
