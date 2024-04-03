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
# The address of current tetrominos
ADDR_CURRENT:
    .word 0x1000C000
# The address of next tetrominos
ADDR_NEXT:
    .word 0x1000d000

    
# - $v0: the service number of 'syscall'
# - $v1:
# - $a0: the argument that is operated by 'syscall'
# - $a1: the color value to draw on the bitmap
# - $a2: the type of the tetromino
# - $a3: the address of landed tetrominos (ADDR_TETR)
# - $t0: how many milisecond has passed
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

addi $a2, $zero, 'T'
sw $a2, ADDR_NEXT    # $a2 = address of current tetrominos
addi $a2, $zero, 'O'
sw $a2, ADDR_CURRENT    # $a2 = address of current tetrominos


main_loop:
sw $a2, ADDR_CURRENT    # $a2 = address of current tetrominos

# Initialize the game
lw $s4, ADDR_DSPL       # $s4 = base address for display
lw $s5, ADDR_KBRD       # $s5 = address of keyboard
lw $s6, ADDR_GRID       # $s6 = address of grid
lw $s7, ADDR_WALL       # $s7 = address of walls
lw $a3, ADDR_TETR       # $a3 = address of landed tetrominos

jal clear_borad

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
jal draw_tetromino

# Draw next tetromino on the side
addi $t0, $zero, 25      # set x coordinate of line
addi $t1, $zero, 10      # set y coordinate of line
lw $a2, ADDR_NEXT
jal draw_next_tetromino
lw $a2, ADDR_CURRENT

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
        li $a1, 0xE3C256            # $a1 = Old Glod
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

    sll $t4, $t1, 7         # convert vertical offset to pixels (by multiplying $t1 by 128)
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
    # li $a1, 0xff0000        # $a1 = red
    addi $t3, $zero, 52     # the started point is fixed in the middle of the rectangle
    add $t7, $zero, $t3     # store the total offset of the starting pixel for moving the tetromino in the game loop
    add $t3, $s4, $t3       # calculate the location of the starting pixel ($s4 + offset)
    
    # draw shape by $a2
    bne $a2, 'O', I
    li $a1, 0x586994        # $a1 = Waikawa Grey
    sw $a1, 0($t3)
    sw $a1, 4($t3)
    sw $a1, 128($t3)
    sw $a1, 132($t3)
    add $s0, $t7, $zero
    addi $s1, $t7, 4
    addi $s2, $t7, 132
    addi $s3, $t7, 128
    
    j end_tetromino
    
    I:
    bne $a2, 'I', S
    li $a1, 0x7ea172        # $a1 = Greeny Grey
    sw $a1, 0($t3)
    sw $a1, 128($t3)
    sw $a1, 256($t3)
    sw $a1, 384($t3)
    addi $s0, $t7, 128
    add $s1, $t7, $zero
    addi $s2, $t7, 256
    addi $s3, $t7, 384

    j end_tetromino
    
    S:
    bne $a2, 'S', Z
    li $a1, 0xc7cb85        # $a1 = Pale Olive
    sw $a1, 0($t3)
    sw $a1, 4($t3)
    sw $a1, 128($t3)
    sw $a1, 124($t3)
    addi $s0, $t7, 124
    add $s1, $t7, $zero
    addi $s2, $t7, 4
    addi $s3, $t7, 128
    
    j end_tetromino
    
    Z:
    bne $a2, 'Z', L
    li $a1, 0xe7a977        # $a1 = Brown Sugar
    sw $a1, 0($t3)
    sw $a1, 4($t3)
    sw $a1, 132($t3)
    sw $a1, 136($t3)
    add $s0, $t7, $zero
    addi $s1, $t7, 4
    addi $s2, $t7, 136
    addi $s3, $t7, 132
    
    j end_tetromino
    
    L:
    bne $a2, 'L', J
    li $a1, 0x644536        # $a1 = Purple Brown
    sw $a1, 0($t3)
    sw $a1, 128($t3)
    sw $a1, 256($t3)
    sw $a1, 260($t3)
    addi $s0, $t7, 128
    add $s1, $t7, $zero
    addi $s2, $t7, 260
    addi $s3, $t7, 256
    
    j end_tetromino
    
    J:
    bne $a2, 'J', T
    li $a1, 0xcc2936        # $a1 = Persian Red
    sw $a1, 0($t3)
    sw $a1, 128($t3)
    sw $a1, 256($t3)
    sw $a1, 252($t3)
    addi $s0, $t7, 252
    add $s1, $t7, $zero
    addi $s2, $t7, 128
    addi $s3, $t7, 256
    
    j end_tetromino
    
    T:
    li $a1, 0xE37F1B        # $a1 = Blue Chalk
    sw $a1, 0($t3)
    sw $a1, 4($t3)
    sw $a1, 132($t3)
    sw $a1, 8($t3)
    add $s0, $t7, $zero
    addi $s1, $t7, 4
    addi $s2, $t7, 8
    addi $s3, $t7, 132
    
    end_tetromino:
    jr $ra                      # return to calling program

# $a1 is the color value to draw on the bitmap, $a2 is the type of the tetromino, $t0 is x-coordinate, $t1 is y-coordinate
draw_next_tetromino:
    sll $t4, $t1, 7         # convert vertical offset to pixels (by multiplying $t1 by 128)
    sll $t3, $t0, 2         # convert horizontal offset to pixels (by multiplying $t0 by 4)
    
    add $t3, $t3, $t4
    add $t3, $t3, $s4
    
    addi $sp, $sp, -4
    sw $a1, 0($sp)          # store the color of the previous tetrominoes
    # clear befor
    li $a1, 0x0        #a1 = black
    sw $a1, -4($t3)
    sw $a1, 0($t3)
    sw $a1, 4($t3)
    sw $a1, 8($t3)
    sw $a1, 12($t3)
    sw $a1, 124($t3)
    sw $a1, 128($t3)
    sw $a1, 132($t3)
    sw $a1, 136($t3)
    sw $a1, 140($t3)
    sw $a1, 252($t3)
    sw $a1, 256($t3)
    sw $a1, 260($t3)
    sw $a1, 264($t3)
    sw $a1, 268($t3)
    sw $a1, 380($t3)
    sw $a1, 384($t3)
    sw $a1, 388($t3)
    sw $a1, 392($t3)
    sw $a1, 396($t3)
    sw $a1, 512($t3)
    
    # li $a1, 0xff0000        # $a1 = red
    
    
    # draw shape by $a2
    bne $a2, 'O', I_next
    li $a1, 0x586994        # $a1 = Waikawa Grey
    sw $a1, 0($t3)
    sw $a1, 4($t3)
    sw $a1, 128($t3)
    sw $a1, 132($t3)
    
    j end__next_tetromino
    
    I_next:
    bne $a2, 'I', S_next
    li $a1, 0x7ea172        # $a1 = Greeny Grey
    sw $a1, 0($t3)
    sw $a1, 128($t3)
    sw $a1, 256($t3)
    sw $a1, 384($t3)

    j end__next_tetromino
    
    S_next:
    bne $a2, 'S', Z_next
    li $a1, 0xc7cb85        # $a1 = Pale Olive
    sw $a1, 0($t3)
    sw $a1, 4($t3)
    sw $a1, 128($t3)
    sw $a1, 124($t3)
    
    j end__next_tetromino
    
    Z_next:
    bne $a2, 'Z', L_next
    li $a1, 0xe7a977        # $a1 = Brown Sugar
    sw $a1, 0($t3)
    sw $a1, 4($t3)
    sw $a1, 132($t3)
    sw $a1, 136($t3)

    j end__next_tetromino
    
    L_next:
    bne $a2, 'L', J_next
    li $a1, 0x644536        # $a1 = Purple Brown
    sw $a1, 0($t3)
    sw $a1, 128($t3)
    sw $a1, 256($t3)
    sw $a1, 260($t3)
    addi $s0, $t7, 128
    add $s1, $t7, $zero
    addi $s2, $t7, 260
    addi $s3, $t7, 256
    
    j end__next_tetromino
    
    J_next:
    bne $a2, 'J', T_next
    li $a1, 0xcc2936        # $a1 = Persian Red
    sw $a1, 0($t3)
    sw $a1, 128($t3)
    sw $a1, 256($t3)
    sw $a1, 252($t3)
    j end__next_tetromino
    
    T_next:
    li $a1, 0xE37F1B        # $a1 = Fulvous
    sw $a1, 0($t3)
    sw $a1, 4($t3)
    sw $a1, 132($t3)
    sw $a1, 8($t3)
    
    end__next_tetromino:
    lw $a1, 0($sp)
    addi $sp, $sp, 4
    jr $ra                      # return to calling program

# check if t1, t2, t3, t4 (new) transfering from s0, s1, s2, s3 (old) is valid tansfer
Check_valid_position_left_right:
    #t1
    #check if t1 overlap with any previous pixel
    beq $t1, $s0, check_t2
    beq $t1, $s1, check_t2
    beq $t1, $s2, check_t2
    beq $t1, $s3, check_t2
    # if not overlap, check if overlap with wall or landed tetrominoes
    add $t6, $a3, $t1               # calculate the location of the leftest pixel in the ADDR_TETR
    lw $t5, 0($t6)                  # load the color of this position in ADDR_TETR
    bne $zero, $t5, game_loop       # if this postion has landed tetrominoes(has color), ignore the pressing.
    add $t6, $s7, $t1               # calculate the location of the leftest pixel in the ADDR_WALL
    lw $t5, 0($t6)                  # load the color of this position in ADDR_WALL
    bne $zero, $t5, game_loop       # if this postion is the wall(has color), ignore the pressing.
    
    check_t2:
    #t2
    #check if t2 overlap with any previous pixel
    beq $t2, $s0, check_t3
    beq $t2, $s1, check_t3
    beq $t2, $s2, check_t3
    beq $t2, $s3, check_t3
    # if not overlap, check if overlap with wall or landed tetrominoes
    add $t6, $a3, $t2               # calculate the location of the leftest pixel in the ADDR_TETR
    lw $t5, 0($t6)                  # load the color of this position in ADDR_TETR
    bne $zero, $t5, game_loop       # if this postion has landed tetrominoes(has color), ignore the pressing.
    add $t6, $s7, $t2               # calculate the location of the leftest pixel in the ADDR_WALL
    lw $t5, 0($t6)                  # load the color of this position in ADDR_WALL
    bne $zero, $t5, game_loop       # if this postion is the wall(has color), ignore the pressing.
    
    check_t3:
    #t3
    #check if t3 overlap with any previous pixel
    beq $t3, $s0, check_t4
    beq $t3, $s1, check_t4
    beq $t3, $s2, check_t4
    beq $t3, $s3, check_t4
    # if not overlap, check if overlap with wall or landed tetrominoes
    add $t6, $a3, $t3               # calculate the location of the leftest pixel in the ADDR_TETR
    lw $t5, 0($t6)                  # load the color of this position in ADDR_TETR
    bne $zero, $t5, game_loop       # if this postion has landed tetrominoes(has color), ignore the pressing.
    add $t6, $s7, $t3               # calculate the location of the leftest pixel in the ADDR_WALL
    lw $t5, 0($t6)                  # load the color of this position in ADDR_WALL
    bne $zero, $t5, game_loop       # if this postion is the wall(has color), ignore the pressing.
    
    check_t4:
     #t4
    #check if t4 overlap with any previous pixel
    beq $t4, $s0, check_end
    beq $t4, $s1, check_end
    beq $t4, $s2, check_end
    beq $t4, $s3, check_end
    # if not overlap, check if overlap with wall or landed tetrominoes
    add $t6, $a3, $t4               # calculate the location of the leftest pixel in the ADDR_TETR
    lw $t5, 0($t6)                  # load the color of this position in ADDR_TETR
    bne $zero, $t5, game_loop       # if this postion has landed tetrominoes(has color), ignore the pressing.
    add $t6, $s7, $t4               # calculate the location of the leftest pixel in the ADDR_WALL
    lw $t5, 0($t6)                  # load the color of this position in ADDR_WALL
    bne $zero, $t5, game_loop       # if this postion is the wall(has color), ignore the pressing.
        
    check_end:
    jr $ra                      # return to calling program


# check if t1, t2, t3, t4 (new) transfering from s0, s1, s2, s3 (old) is valid tansfer
Check_valid_position_down:
    #t1
    #check if t1 overlap with any previous pixel
    beq $t1, $s0, check_t2_d
    beq $t1, $s1, check_t2_d
    beq $t1, $s2, check_t2_d
    beq $t1, $s3, check_t2_d
    # if not overlap, check if overlap with wall or landed tetrominoes
    add $t6, $a3, $t1               # calculate the location of the leftest pixel in the ADDR_TETR
    lw $t5, 0($t6)                  # load the color of this position in ADDR_TETR
    bne $zero, $t5, land       # if this postion has landed tetrominoes(has color), ignore the pressing.
    add $t6, $s7, $t1               # calculate the location of the leftest pixel in the ADDR_WALL
    lw $t5, 0($t6)                  # load the color of this position in ADDR_WALL
    bne $zero, $t5, land       # if this postion is the wall(has color), ignore the pressing.
    
    check_t2_d:
    #t2
    #check if t2 overlap with any previous pixel
    beq $t2, $s0, check_t3_d
    beq $t2, $s1, check_t3_d
    beq $t2, $s2, check_t3_d
    beq $t2, $s3, check_t3_d
    # if not overlap, check if overlap with wall or landed tetrominoes
    add $t6, $a3, $t2               # calculate the location of the leftest pixel in the ADDR_TETR
    lw $t5, 0($t6)                  # load the color of this position in ADDR_TETR
    bne $zero, $t5, land       # if this postion has landed tetrominoes(has color), ignore the pressing.
    add $t6, $s7, $t2               # calculate the location of the leftest pixel in the ADDR_WALL
    lw $t5, 0($t6)                  # load the color of this position in ADDR_WALL
    bne $zero, $t5, land       # if this postion is the wall(has color), ignore the pressing.
    
    check_t3_d:
    #t3
    #check if t3 overlap with any previous pixel
    beq $t3, $s0, check_t4_d
    beq $t3, $s1, check_t4_d
    beq $t3, $s2, check_t4_d
    beq $t3, $s3, check_t4_d
    # if not overlap, check if overlap with wall or landed tetrominoes
    add $t6, $a3, $t3               # calculate the location of the leftest pixel in the ADDR_TETR
    lw $t5, 0($t6)                  # load the color of this position in ADDR_TETR
    bne $zero, $t5, land       # if this postion has landed tetrominoes(has color), ignore the pressing.
    add $t6, $s7, $t3               # calculate the location of the leftest pixel in the ADDR_WALL
    lw $t5, 0($t6)                  # load the color of this position in ADDR_WALL
    bne $zero, $t5, land       # if this postion is the wall(has color), ignore the pressing.
    
    check_t4_d:
     #t4
    #check if t4 overlap with any previous pixel
    beq $t4, $s0, check_end_d
    beq $t4, $s1, check_end_d
    beq $t4, $s2, check_end_d
    beq $t4, $s3, check_end_d
    # if not overlap, check if overlap with wall or landed tetrominoes
    add $t6, $a3, $t4               # calculate the location of the leftest pixel in the ADDR_TETR
    lw $t5, 0($t6)                  # load the color of this position in ADDR_TETR
    bne $zero, $t5, land       # if this postion has landed tetrominoes(has color), ignore the pressing.
    add $t6, $s7, $t4               # calculate the location of the leftest pixel in the ADDR_WALL
    lw $t5, 0($t6)                  # load the color of this position in ADDR_WALL
    bne $zero, $t5, land       # if this postion is the wall(has color), ignore the pressing.
        
    check_end_d:
    jr $ra                      # return to calling program
    
# this function paint s0, s1, s2, s3 with the tetromino colour -> fraw tetromino with given location
Draw_tetromino_with_location:
    add $t1, $s4, $s0               # calculate the location of the leftest pixel in the bitmap
    sw $a1, 0($t1)
    add $t1, $s4, $s1
    sw $a1, 0($t1)
    add $t1, $s4, $s2
    sw $a1, 0($t1)
    add $t1, $s4, $s3
    sw $a1, 0($t1)
    jr $ra                      # return to calling program
    

# earese current tetromino to background color
Delete_current_tetrominos:
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
    
    jr $ra                      # return to calling program
    

rotate_O:
    jal Delete_current_tetrominos
    j rotate_end
    
rotate_I:
    addi $t1, $s1, 128
    beq $t1, $s0, rotate_I_horizontal # check if I is vertical
    # if I is horizatonl -> rotate vertical
    addi $t4, $s1, 128
    addi $t2, $s1, 256
    addi $t3, $s1, 384
    addi $t1, $s1, 0
    jal Check_valid_position_left_right
    
    jal Delete_current_tetrominos
    
    addi $s0, $s1, 128
    addi $s2, $s1, 256
    addi $s3, $s1, 384
    j rotate_end
    
    rotate_I_horizontal:
    addi $t1, $s1, 4
    jal Check_color
    bne $t5, $zero, rotate_I_three_left
    bne $t6, $zero, rotate_I_three_left
    
    addi $t1, $s1, 8
    jal Check_color
    bne $t5, $zero, rotate_I_two_left
    bne $t6, $zero, rotate_I_two_left
    
    addi $t1, $s1, 12
    jal Check_color
    bne $t5, $zero, rotate_I_one_left
    bne $t6, $zero, rotate_I_one_left
    
    addi $t4, $s1, 4
    addi $t2, $s1, 8
    addi $t3, $s1, 12
    addi $t1, $s1, 0
    
    jal Check_valid_position_left_right
    jal Delete_current_tetrominos
    
    addi $s0, $s1, 4
    addi $s2, $s1, 8
    addi $s3, $s1, 12
    j rotate_end
    
    rotate_I_three_left:
    subi $t1, $s1, 12
    addi $t4, $t1, 4
    addi $t2, $t1, 8
    addi $t3, $t1, 12
    
    jal Check_valid_position_left_right
    
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end
        
    
    rotate_I_two_left:
    subi $t1, $s1, 8
    addi $t4, $t1, 4
    addi $t2, $t1, 8
    addi $t3, $t1, 12
    
    jal Check_valid_position_left_right
        
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end
    
    rotate_I_one_left:
    subi $t1, $s1, 4
    addi $t4, $t1, 4
    addi $t2, $t1, 8
    addi $t3, $t1, 12
    
    jal Check_valid_position_left_right
        
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end
    


    
rotate_S:
    addi $t1, $s1, 4
    beq $t1, $s2, rotate_S_vertical # check if S is horizontal
    
    # if vertical -> horizontal
    subi $t1, $s0, 120
    jal Check_color
    bne $t5, $zero, rotate_S_one_left
    bne $t6, $zero, rotate_S_one_left
        
        
    subi $t1, $s0, 124
    subi $t2, $s0, 120
    addi $t3, $s0, 4
    addi $t4, $s0, 0
    jal Check_valid_position_left_right
    
    jal Delete_current_tetrominos
    
    
    subi $s1, $s0, 124
    subi $s2, $s0, 120
    addi $s3, $s0, 4
    j rotate_end
    
    rotate_S_one_left:
    subi $t4, $s0, 4
    addi $t3, $t4, 4
    subi $t1, $t3, 128
    addi $t2, $t1, 4
    
    jal Check_valid_position_left_right
    
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end
    
    # if horizatonl -> rotate vertical
    rotate_S_vertical:
    subi $t1, $s0, 128
    addi $t2, $s0, 4
    addi $t3, $s0, 132
    addi $t4, $s0, 0
    jal Check_valid_position_left_right
    
    jal Delete_current_tetrominos
    
    subi $s1, $s0, 128
    addi $s2, $s0, 4
    addi $s3, $s0, 132
    j rotate_end
    
rotate_Z:
    addi $t1, $s0, 4
    beq $t1, $s1, rotate_Z_vertical # check if S is horizontal
    # if vertical -> horizontal
    addi $t1, $s0, 4
    jal Check_color
    bne $t5, $zero, rotate_Z_two_left
    bne $t6, $zero, rotate_Z_two_left
    
    addi $t1, $s0, 8
    jal Check_color
    bne $t5, $zero, rotate_Z_one_left
    bne $t6, $zero, rotate_Z_one_left
    
    addi $t1, $s0, 4
    addi $t2, $s0, 132
    addi $t3, $s0, 136
    addi $t4, $s0, 0
    jal Check_valid_position_left_right

    jal Delete_current_tetrominos
    
    addi $s1, $s0, 4
    addi $s2, $s0, 132
    addi $s3, $s0, 136
    j rotate_end
    
    rotate_Z_one_left:
    subi $t4, $s0, 4
    addi $t1, $t4, 4
    addi $t3, $t1, 128
    addi $t2, $t3, 4
    
    jal Check_valid_position_left_right
        
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end
    
    rotate_Z_two_left:
    subi $t4, $s0, 8
    addi $t1, $t4, 4
    addi $t3, $t1, 128
    addi $t2, $t3, 4
    
    jal Check_valid_position_left_right
        
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end
    
    # if horizatonl -> rotate vertical
    rotate_Z_vertical:
    subi $t1, $s0, 4
    jal Check_color
    bne $t5, $zero, rotate_Z_one_right
    bne $t6, $zero, rotate_Z_one_right
    
    addi $t1, $s0, 128
    addi $t2, $s0, 124
    addi $t3, $s0, 252
    addi $t4, $s0, 0
    jal Check_valid_position_left_right
    jal Delete_current_tetrominos
    
    addi $s1, $s0, 128
    addi $s2, $s0, 124
    addi $s3, $s0, 252
    j rotate_end
    
    rotate_Z_one_right:
    addi $t4, $s0, 4
    addi $t1, $t4, 128
    addi $t2, $t4, 124
    addi $t3, $t4, 252
    
    jal Check_valid_position_left_right
        
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end
    
rotate_L:
    addi $t1, $s3, 4
    beq $t1, $s2, rotate_L_type_1 # check if L is type 1
    beq $t1, $s0, rotate_L_type_2 # check if L is type 2
    subi $t1, $s3, 4
    beq $t1, $s2, rotate_L_type_3 # check if L is type 3
    
    # L is type 4
    addi $t1, $s2, 4
    jal Check_color
    bne $t5, $zero, rotate_L_type_4_left
    bne $t6, $zero, rotate_L_type_4_left
    
    addi $t2, $s3, 4
    subi $t4, $s3, 128
    subi $t1, $s3, 256
    addi $t3, $s3, 0
    jal Check_valid_position_left_right
    jal Delete_current_tetrominos
    
    addi $s2, $s3, 4
    subi $s0, $s3, 128
    subi $s1, $s3, 256
    j rotate_end
    
    rotate_L_type_4_left:
    subi $t3, $s3, 4
    addi $t2, $t3, 4
    subi $t4, $t3, 128
    subi $t1, $t3, 256
    
    jal Check_valid_position_left_right
        
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end

    rotate_L_type_1:
    addi $t1, $s2, 4
    jal Check_color
    bne $t5, $zero, rotate_L_type_1_left
    bne $t6, $zero, rotate_L_type_1_left
    
    addi $t4, $s3, 4
    addi $t1, $s3, 8
    addi $t2, $s3, 128
    addi $t3, $s3, 0
    jal Check_valid_position_left_right
    jal Delete_current_tetrominos
    
    addi $s0, $s3, 4
    addi $s1, $s3, 8
    addi $s2, $s3, 128
    j rotate_end
    
    rotate_L_type_1_left:
    subi $t3, $s3, 4
    addi $t1, $t3, 8
    addi $t2, $t3, 128
    addi $t4, $t3, 4
    
    jal Check_valid_position_left_right
        
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end
    
    rotate_L_type_2:
    subi $t1, $s2, 4
    jal Check_color
    bne $t5, $zero, rotate_L_type_2_right
    bne $t6, $zero, rotate_L_type_2_right
 
    addi $t4, $s3, 128
    addi $t1, $s3, 256
    subi $t2, $s3, 4
    addi $t3, $s3, 0
    jal Check_valid_position_left_right
    jal Delete_current_tetrominos
    
    addi $s0, $s3, 128
    addi $s1, $s3, 256
    subi $s2, $s3, 4
    j rotate_end
    
    rotate_L_type_2_right:
    addi $t3, $s3, 4
    addi $t1, $t3, 256
    subi $t2, $t3, 4
    addi $t4, $t3, 128
    
    jal Check_valid_position_left_right
        
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end
    
    rotate_L_type_3:
    subi $t1, $s2, 4
    jal Check_color
    bne $t5, $zero, rotate_L_type_3_right
    bne $t6, $zero, rotate_L_type_3_right

    subi $t4, $s3, 4
    subi $t1, $s3, 8
    subi $t2, $s3, 128
    addi $t3, $s3, 0
    jal Check_valid_position_left_right
    jal Delete_current_tetrominos
    
    subi $s0, $s3, 4
    subi $s1, $s3, 8
    subi $s2, $s3, 128
    j rotate_end
    
    rotate_L_type_3_right:
    addi $t3, $s3, 4
    subi $t1, $t3, 8
    subi $t2, $t3, 128
    subi $t4, $t3, 4
    
    jal Check_valid_position_left_right
        
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end
    
rotate_J:
    subi $t1, $s3, 4
    beq $t1, $s0, rotate_J_type_1 # check if L is type 1
    beq $t1, $s2, rotate_J_type_4 # check if L is type 2
    addi $t1, $s3, 4
    beq $t1, $s0, rotate_J_type_3 # check if L is type 3
    
    addi $t4, $s3, 4
    addi $t2, $s3, 128
    addi $t1, $s3, 256
    addi $t3, $s3, 0
    jal Check_valid_position_left_right
    jal Delete_current_tetrominos
    
    # J is type 2
    addi $s0, $s3, 4
    addi $s2, $s3, 128
    addi $s1, $s3, 256
    j rotate_end

    rotate_J_type_1:
    addi $t1, $s3, 4
    jal Check_color
    bne $t5, $zero, rotate_J_type_1_two_left
    bne $t6, $zero, rotate_J_type_1_two_left
    
    addi $t1, $s3, 8
    jal Check_color
    bne $t5, $zero, rotate_J_type_1_one_left
    bne $t6, $zero, rotate_J_type_1_one_left
        
    subi $t4, $s3, 128
    addi $t1, $s3, 8
    addi $t2, $s3, 4
    addi $t3, $s3, 0
    jal Check_valid_position_left_right
    jal Delete_current_tetrominos
    
    subi $s0, $s3, 128
    addi $s1, $s3, 8
    addi $s2, $s3, 4
    j rotate_end
    
    rotate_J_type_1_two_left:
    subi $t3, $s3, 8
    subi $t4, $t3, 128
    addi $t1, $t3, 8
    addi $t2, $t3, 4
    
    jal Check_valid_position_left_right
        
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end
    
    rotate_J_type_1_one_left:
    subi $t3, $s3, 4
    subi $t4, $t3, 128
    addi $t1, $t3, 8
    addi $t2, $t3, 4
    
    jal Check_valid_position_left_right
        
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end
    
    
    rotate_J_type_3:
    subi $t1, $s3, 4
    jal Check_color
    bne $t5, $zero, rotate_J_type_3_two_right
    bne $t6, $zero, rotate_J_type_3_two_right
    
    subi $t1, $s3, 8
    jal Check_color
    bne $t5, $zero, rotate_J_type_3_one_right
    bne $t6, $zero, rotate_J_type_3_one_right
    
    addi $t4, $s3, 128
    subi $t1, $s3, 8
    subi $t2, $s3, 4
    addi $t3, $s3, 0
    jal Check_valid_position_left_right
    jal Delete_current_tetrominos
    
    addi $s0, $s3, 128
    subi $s1, $s3, 8
    subi $s2, $s3, 4
    j rotate_end
    
    rotate_J_type_3_two_right:
    addi $t3, $s3, 8
    addi $t4, $t3, 128
    subi $t1, $t3, 8
    subi $t2, $t3, 4
    
    jal Check_valid_position_left_right
        
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end
    
    rotate_J_type_3_one_right:
    
    addi $t3, $s3, 4
    addi $t4, $t3, 128
    subi $t1, $t3, 8
    subi $t2, $t3, 4
    
    jal Check_valid_position_left_right
        
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end
    
    
    rotate_J_type_4:
    subi $t4, $s3, 4
    subi $t1, $s3, 256
    subi $t2, $s3, 128   
    addi $t3, $s3, 0
    jal Check_valid_position_left_right
    jal Delete_current_tetrominos
    
    subi $s0, $s3, 4
    subi $s1, $s3, 256
    subi $s2, $s3, 128
    j rotate_end
    
rotate_T:
    addi $t1, $s1, 4
    beq $t1, $s0, rotate_T_type_3 # check if L is type 1
    beq $t1, $s2, rotate_T_type_1 # check if L is type 2
    beq $t1, $s3, rotate_T_type_4 # check if L is type 3
    
    # T is type 2
    addi $t1, $s1, 4
    jal Check_color
    bne $t5, $zero, rotate_T_type_2_left
    bne $t6, $zero, rotate_T_type_2_left
    
    addi $t4, $s1, 4
    subi $t2, $s1, 4
    subi $t3, $s1, 128    
    addi $t1, $s1, 0
    jal Check_valid_position_left_right
    jal Delete_current_tetrominos
    
    addi $s0, $s1, 4
    subi $s2, $s1, 4
    subi $s3, $s1, 128
    j rotate_end
    
    rotate_T_type_2_left:
    
    subi $t1, $s1, 4
    addi $t4, $t1, 4
    subi $t2, $t1, 4
    subi $t3, $t1, 128
    
    jal Check_valid_position_left_right
        
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end

    rotate_T_type_1:
    addi $t2, $s1, 128
    subi $t3, $s1, 4
    subi $t4, $s1, 128
    addi $t1, $s1, 0
    jal Check_valid_position_left_right
        
    jal Delete_current_tetrominos
    
    addi $s2, $s1, 128
    subi $s3, $s1, 4
    subi $s0, $s1, 128
    j rotate_end
    
    rotate_T_type_3:
    addi $t3, $s1, 4
    subi $t2, $s1, 128
    addi $t4, $s1, 128
    addi $t1, $s1, 0
    jal Check_valid_position_left_right
    jal Delete_current_tetrominos
    
    addi $s3, $s1, 4
    subi $s2, $s1, 128
    addi $s0, $s1, 128
    j rotate_end
    
    rotate_T_type_4:
    subi $t1, $s1, 4
    jal Check_color
    bne $t5, $zero, rotate_T_type_4_right
    bne $t6, $zero, rotate_T_type_4_right
     
    addi $t2, $s1, 4
    addi $t3, $s1, 128
    subi $t4, $s1, 4    
    addi $t1, $s1, 0
    jal Check_valid_position_left_right
    jal Delete_current_tetrominos
    
    addi $s2, $s1, 4
    addi $s3, $s1, 128
    subi $s0, $s1, 4
    j rotate_end
    
    rotate_T_type_4_right:
        
    addi $t1, $s1, 4
    subi $t4, $t1, 4
    addi $t2, $t1, 4
    addi $t3, $t1, 128
    
    jal Check_valid_position_left_right
        
    jal Delete_current_tetrominos
    
    addi $s0, $t4, 0
    addi $s1, $t1, 0
    addi $s2, $t2, 0
    addi $s3, $t3, 0
    
    j rotate_end
    
rotate_end:
    jal Draw_tetromino_with_location

    j end_rotate

clear_borad:
    addi $t0, $zero, 0      # set x coordinate of line
    addi $t1, $zero, 0      # set y coordinate of line
    addi $t2, $zero, 32      # set length of line
    addi $t3, $zero, 32      # set height of line
    
    sll $t4, $t1, 7         # convert vertical offset to pixels (by multiplying $t1 by 128)
    sll $t5, $t3, 7         # convert height of rectangle from pixels to rows of bytes (by multiplying $t3 by 128)
    add $t5, $t4, $t5       # calculate value of $t4 for the last line in the rectangle.
    
    outer_top_clear:
        sll $t6, $t0, 2         # convert horizontal offset to pixels (by multiplying $t0 by 4)
        sll $t7, $t2, 2         # convert length of line from pixels to bytes (by multiplying $t2 by 4)
        add $t7, $t6, $t7       # calculate value of $t4 for end of the horizontal line.
        
    inner_top_clear:
        add $t9, $t6, $t4           # store the total offset of the starting pixel (relative to $s4)
        add $t8, $s7, $t9           # store the total offset of the starting pixel for storing wall ($s7 + offset)
        add $t9, $s4, $t9           # calculate the location of the starting pixel ($s4 + offset)
        li $a1, 0x000000            # $a1 = black
        sw $a1, 0($t9)              # paint the current unit on the first row green
        sw $a1, 0($t8)
        addi $t6, $t6, 4            # move horizontal offset to the right by one pixel
        beq $t6, $t7, inner_end_clear     # break out of the line-drawing loop
        j inner_top_clear                 # jump to the start of the inner loop
        
    inner_end_clear:
        addi $t4, $t4, 128          # move vertical offset down by one line
        beq $t4, $t5, outer_end_clear     # on last line, break out of the outer loop
        j outer_top_clear                 # jump to the top of the outer loop
        
    outer_end_clear:
        jr $ra                      # return to calling program

# check $t1's colour, t5 will return colour in tetromino, t6 will return colour in wall
Check_color:
    # if not overlap, check if overlap with wall or landed tetrominoes
    add $t5, $a3, $t1               # calculate the location of the leftest pixel in the ADDR_TETR
    lw $t5, 0($t5)                  # load the color of this position in ADDR_TETR

    add $t6, $s7, $t1               # calculate the location of the leftest pixel in the ADDR_WALL
    lw $t6, 0($t6)                  # load the color of this position in ADDR_WALL
    
    jr $ra
    

    
    
SKIP_FUNCTION:  

#################################################################################################################################################
#################################################################################################################################################
#################################################################################################################################################
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
    li $v0, 32                     # service number = sleep
	li $a0, 1                      # $a0 = the length of time to sleep in milliseconds
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
    # jal Delete_current_tetrominos
    
    beq $a2, 'O', rotate_O
	beq $a2, 'I', rotate_I
	beq $a2, 'S', rotate_S
	beq $a2, 'Z', rotate_Z
	beq $a2, 'L', rotate_L
	beq $a2, 'J', rotate_J
	beq $a2, 'T', rotate_T
    end_rotate:
    j game_loop

respond_to_A:                       # let the tertromino move left for 1 pixel
    # check if it moves against the left wall and landed tetrominoes
    # calculate the new offset after moving left
    subi $t1, $s0, 4
    subi $t2, $s1, 4
    subi $t3, $s2, 4
    subi $t4, $s3, 4
    jal Check_valid_position_left_right

    # subi $s0, $s0, 4                # calculate the new offset after moving left
    # add $t4, $a3, $s0               # calculate the location of the leftest pixel in the ADDR_TETR
    # add $t1, $s7, $s0               # calculate the location of the leftest pixel in the ADDR_WALL
    # addi $s0, $s0, 4
    # lw $t5, 0($t4)                  # load the color of this position in ADDR_TETR
    # bne $zero, $t5, game_loop       # if this postion has landed tetrominoes(has color), ignore the pressing.
    # lw $t5, 0($t1)                  # load the color of this position in ADDR_WALL
    # bne $zero, $t5, game_loop       # if this postion is the wall(has color), ignore the pressing.
    
    # jal Delete_current_tetrominos
    
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
    #check if it moves against the bottom wall and the landed tetrominos
    addi $t1, $s0, 128
    addi $t2, $s1, 128
    addi $t3, $s2, 128
    addi $t4, $s3, 128
    jal Check_valid_position_down

    # addi $s3, $s3, 128              # calculate the new offset after moving down
    # add $t4, $a3, $s3               # calculate the location of the leftest pixel in the ADDR_TETR
    # add $t1, $s7, $s3               # calculate the location of the leftest pixel in the ADDR_WALL
    # subi $s3, $s3, 128
    # lw $t5, 0($t4)                  # load the color of this position in ADDR_TETR
    # bne $zero, $t5, land            # # if this postion has landed tetrominoes(has color), the tetromino is landed.
    # lw $t5, 0($t1)                  # load the color of this position in ADDR_WALL
    # bne $zero, $t5, land            # if this postion is the wall(has color), the tetromino is landed.
    
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
    
    # jal Delete_current_tetrominos

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
    # calculate the new offset after moving left
    addi $t1, $s0, 4
    addi $t2, $s1, 4
    addi $t3, $s2, 4
    addi $t4, $s3, 4
    jal Check_valid_position_left_right

    # addi $s2, $s2, 4                # calculate the new offset after moving left
    # add $t4, $a3, $s0               # calculate the location of the leftest pixel in the ADDR_TETR
    # add $t1, $s7, $s2               # calculate the location of the leftest pixel in the ADDR_WALL
    # subi $s2, $s2, 4
    # lw $t5, 0($t4)                  # load the color of this position in ADDR_TETR
    # bne $zero, $t5, game_loop       # if this postion has landed tetrominoes(has color), ignore the pressing.
    # lw $t5, 0($t1)                  # load the color of this position in ADDR_WALL
    # bne $zero, $t5, game_loop       # if this postion is the wall(has color), ignore the pressing.
    
    # jal Delete_current_tetrominos
    
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
    # generate random tetromino type
    # generate random number use syscall
    li $v0, 42
    li $a0, 0
    addi $sp, $sp, -4
    sw $a1, 0($sp)
    li $a1, 7
    syscall
    
    lw $a2, ADDR_NEXT
    sw $a2, ADDR_CURRENT
    
    beq $a0, 0, random_0
    beq $a0, 1, random_1
    beq $a0, 2, random_2
    beq $a0, 3, random_3
    beq $a0, 4, random_4
    beq $a0, 5, random_5
    beq $a0, 6, random_6
    j random_end
    
    random_0:
    addi $a2, $zero, 'O'
    sw $a2, ADDR_NEXT
    j random_end
    random_1:
    addi $a2, $zero, 'I'
    sw $a2, ADDR_NEXT
    j random_end
    random_2:
    addi $a2, $zero, 'S'
    sw $a2, ADDR_NEXT
    j random_end
    random_3:
    addi $a2, $zero, 'Z'
    sw $a2, ADDR_NEXT
    j random_end
    random_4:
    addi $a2, $zero, 'L'
    sw $a2, ADDR_NEXT
    j random_end
    random_5:
    addi $a2, $zero, 'J'
    sw $a2, ADDR_NEXT
    j random_end
    random_6:
    addi $a2, $zero, 'T'
    sw $a2, ADDR_NEXT
    j random_end
    
    random_end:
    
    # change back
    li $v0, 32
    li $a0, 1
    
    lw $a1, 0($sp)
    addi $sp, $sp, 4
    
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    add $t1, $a3, $s0               # calculate the new location of the leftest pixel in stored landed tetrominos
    sw $a1, 0($t1)
    addi $sp, $sp, -4
    sw $t1, 0($sp)
    
    add $t1, $a3, $s1               # calculate the new location of the topmost pixel in stored landed tetrominos
    sw $a1, 0($t1)
    addi $sp, $sp, -4
    sw $t1, 0($sp)
    
    add $t1, $a3, $s2               # calculate the new location of the rightest pixel in stored landed tetrominos
    sw $a1, 0($t1)
    addi $sp, $sp, -4
    sw $t1, 0($sp)
    
    add $t1, $a3, $s3               # calculate the new location of the bottom pixel in stored landed tetrominos
    sw $a1, 0($t1)
    addi $sp, $sp, -4
    sw $t1, 0($sp)
    
    lw $t1, 0($sp)
    addi $sp, $sp, 4
    jal check_line
    lw $t1, 0($sp)
    addi $sp, $sp, 4
    jal check_line
    lw $t1, 0($sp)
    addi $sp, $sp, 4
    jal check_line
    lw $t1, 0($sp)
    addi $sp, $sp, 4
    jal check_line
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    # Draw next tetromino on the side
    addi $t0, $zero, 25      # set x coordinate of line
    addi $t1, $zero, 10      # set y coordinate of line
    lw $a2, ADDR_NEXT
    jal draw_next_tetromino
    
    
    lw $a2, ADDR_CURRENT
    jal draw_tetromino
    
    j game_loop
    
check_line:
    srl $t2, $t1, 7                 # to figure out which line that the tetromino is in
    sll $t2, $t2, 7                 # $t2 = the first value of this line, which we store the total amount of landed pixels
    beq $t2, 0x1000b000, game_over    # if $t2 is the first value in the bitmap, return
    lw $t4, 0($t2)                  # $t4 = the total amount of landed pixels
    addi $t4, $t4, 1                # add the 1 new pixel into the total amount of the landed pixels in this line
    sw $t4, 0($t2)                  # store the new amount of landed pixels
    beq $t4, 14, play_removal_animation        # if there are 14 pixels in this line, play removal animation
    jr $ra
    
play_removal_animation:
    # beq $t2, 0x1000b000, game_over    # if $t2 is the first value in the bitmap, return
    # subi $t2, $t2, 52                       # set $t2 = the last pixel in the rectangle in the last line
    # addi $t3, $zero, 0                      # the count of the total adding pixel, to determine whether jump to next line
    addi $t3, $t2, 24
    addi $t5, $zero, 0
    sub $t3, $t3, $a3
    add $t3, $t3, $s4
    
    add $sp, $sp, 4
    sw $a1, 0($sp)
    li $a1, 0xEEF0F2
    light_pixel:
        sw $a1 0($t3)
        addi $t3, $t3, 4
        addi $t5, $t5, 1
        li $v0, 32                     # service number = sleep
	    li $a0, 20                      # $a0 = the length of time to sleep in milliseconds
	    syscall
        bne $t5, 14, light_pixel
    subi $t2, $t2, 4
    lw $a1, 0($sp)
    add $sp, $sp, -4
    li $v0, 32                     # service number = sleep
	li $a0, 40                      # $a0 = the length of time to sleep in milliseconds
	syscall
    j remove_each_pixel
    
remove_each_pixel:
    addi $t4, $t2, 128              # the position in the next line
    lw $t5, 0($t2)                  # find the value in this postion
    # li $t5, 0x0D21A1
    sw $t5, 0($t4)                  # load the value from the last line in ADDR_TETR
    
    sub $t2, $t2, $a3               # find the offset for calculate the postion in ADDR_DSPL
    add $t2, $t2, $s4
    addi $t4, $t2, 128
    lw $t5, 0($t2)
    # li $t5, 0x0D21A1
    sw $t5, 0($t4)
    sub $t2, $t2, $s4
    add $t2, $t2, $a3
    # addi $t3, $t3, 1
    sub $t2, $t2, 4
    beq $t2, 0x1000b000, end_remove_line
    # bne $t3, 20, remove_each_pixel
    j remove_each_pixel
    
end_remove_line:
    # draw the grid
    li $t3, 0                               # start line
    draw_grid_line:
        li $t2, 24                              # start offset
        draw_grid_pixel:
            add $t4, $t2, $t3
            
            add $t4, $t4, $a3   
            lw $t5, 0($t4)                  # load the value in ADDR_TETR
            sub $t4, $t4, $a3
            
            bne $t5, 0x0, skip_draw_grid    # check if the tetrominos on this pixel
            
            add $t4, $t4, $s6
            lw $t5, 0($t4)                  # load the value in ADDR_GRID
            sub $t4, $t4, $s6
            
            add $t4, $t4, $s4
            sw $t5, 0($t4)                  # draw the color in ADDR_DSPL
            sub $t4, $t4, $s4
            
            skip_draw_grid:
            addi $t2, $t2, 4
            bne $t2, 0x50, draw_grid_pixel
        add $t3, $t3, 128
        bne $t3, 3840, draw_grid_line
    jr $ra

game_over:
    jal clear_borad
    # jal draw_game_over
    
    addi $t0, $zero, 7      # set x coordinate of line
    addi $t1, $zero, 11      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 5      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    addi $t0, $zero, 7      # set x coordinate of line
    addi $t1, $zero, 11      # set y coordinate of line
    addi $t2, $zero, 4      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    addi $t0, $zero, 7      # set x coordinate of line
    addi $t1, $zero, 15      # set y coordinate of line
    addi $t2, $zero, 4      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    addi $t0, $zero, 9      # set x coordinate of line
    addi $t1, $zero, 13      # set y coordinate of line
    addi $t2, $zero, 2      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    addi $t0, $zero, 10      # set x coordinate of line
    addi $t1, $zero, 13      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 2      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    ########### A ##############
    addi $t0, $zero, 12      # set x coordinate of line
    addi $t1, $zero, 11      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 5      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    addi $t0, $zero, 14      # set x coordinate of line
    addi $t1, $zero, 11      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 5      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function

    addi $t0, $zero, 12      # set x coordinate of line
    addi $t1, $zero, 11      # set y coordinate of line
    addi $t2, $zero, 2      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    addi $t0, $zero, 12      # set x coordinate of line
    addi $t1, $zero, 13      # set y coordinate of line
    addi $t2, $zero, 2      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    ########### M ##############
    addi $t0, $zero, 16      # set x coordinate of line
    addi $t1, $zero, 11      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 5      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    addi $t0, $zero, 18      # set x coordinate of line
    addi $t1, $zero, 11      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 5      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    addi $t0, $zero, 20      # set x coordinate of line
    addi $t1, $zero, 11      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 5      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function    
    
    addi $t0, $zero, 16      # set x coordinate of line
    addi $t1, $zero, 11      # set y coordinate of line
    addi $t2, $zero, 5      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    ########### E ##############
    addi $t0, $zero, 22      # set x coordinate of line
    addi $t1, $zero, 11      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 5      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function    
    
    addi $t0, $zero, 22      # set x coordinate of line
    addi $t1, $zero, 11      # set y coordinate of line
    addi $t2, $zero, 3      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    addi $t0, $zero, 22      # set x coordinate of line
    addi $t1, $zero, 13      # set y coordinate of line
    addi $t2, $zero, 3      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    addi $t0, $zero, 22      # set x coordinate of line
    addi $t1, $zero, 15      # set y coordinate of line
    addi $t2, $zero, 3      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    ########### O ##############
    addi $t0, $zero, 7      # set x coordinate of line
    addi $t1, $zero, 17      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 5      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function    
    
    addi $t0, $zero, 7      # set x coordinate of line
    addi $t1, $zero, 17      # set y coordinate of line
    addi $t2, $zero, 4      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function    
    
    addi $t0, $zero, 10      # set x coordinate of line
    addi $t1, $zero, 17      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 5      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function    
    
    addi $t0, $zero, 7      # set x coordinate of line
    addi $t1, $zero, 21      # set y coordinate of line
    addi $t2, $zero, 4      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function    

    ########### V ##############
    addi $t0, $zero, 12      # set x coordinate of line
    addi $t1, $zero, 17      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 2      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function    
    
    addi $t0, $zero, 13      # set x coordinate of line
    addi $t1, $zero, 19      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 2      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function    
    
    addi $t0, $zero, 14      # set x coordinate of line
    addi $t1, $zero, 21      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function    
    
    addi $t0, $zero, 16      # set x coordinate of line
    addi $t1, $zero, 17      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 2      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function    
    
    addi $t0, $zero, 15      # set x coordinate of line
    addi $t1, $zero, 19      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 2      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function      
    
    ########### E ##############
    addi $t0, $zero, 18      # set x coordinate of line
    addi $t1, $zero, 17      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 5      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function    
    
    addi $t0, $zero, 18      # set x coordinate of line
    addi $t1, $zero, 17      # set y coordinate of line
    addi $t2, $zero, 3      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    addi $t0, $zero, 18      # set x coordinate of line
    addi $t1, $zero, 19      # set y coordinate of line
    addi $t2, $zero, 3      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    addi $t0, $zero, 18      # set x coordinate of line
    addi $t1, $zero, 21      # set y coordinate of line
    addi $t2, $zero, 3      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    ########### R ##############
    addi $t0, $zero, 22      # set x coordinate of line
    addi $t1, $zero, 17      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 5      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function    
    
    addi $t0, $zero, 22      # set x coordinate of line
    addi $t1, $zero, 17      # set y coordinate of line
    addi $t2, $zero, 3      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    addi $t0, $zero, 22      # set x coordinate of line
    addi $t1, $zero, 19      # set y coordinate of line
    addi $t2, $zero, 3      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    addi $t0, $zero, 24      # set x coordinate of line
    addi $t1, $zero, 17      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 3      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    addi $t0, $zero, 23      # set x coordinate of line
    addi $t1, $zero, 20      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function
    
    addi $t0, $zero, 24      # set x coordinate of line
    addi $t1, $zero, 21      # set y coordinate of line
    addi $t2, $zero, 1      # set length of line
    addi $t3, $zero, 1      # set height of line
    jal draw_rectangle        # call the rectangle-drawing function

    
    restart:
    addi $t1, $zero, 4096
    addi $t0, $zero, 0
    addi $t5, $zero, 0x0
    
    initialize_landed_loop:
    beq $t0, $t1, initialize_landed_end
    add $t3, $t0, $a3   
    sw $t5, 0($t3)
    addi $t0, $t0, 4
    j initialize_landed_loop
    
    initialize_landed_end:
    
    addi $t1, $zero, 4096
    addi $t0, $zero, 0
    addi $t5, $zero, 0x0
    
    initialize_grid_loop:
    beq $t0, $t1, initialize_grid_end
    add $t3, $t0, $s6   
    sw $t5, 0($t3)
    addi $t0, $t0, 4
    j initialize_grid_loop
    
    initialize_grid_end:
    
    li $a1, 0x0
    
    lw $a0, 4($s5) 
    beq $a0, 0x72, main_loop
    b restart
