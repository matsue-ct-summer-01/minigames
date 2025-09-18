class Gobang
  def initialize
    @board = Array.new(9) { Array.new(9, ' ') }
    @current_player = 'P'
  end

  def print_board
    puts "  0 1 2 3 4 5 6 7 8"
    puts "-------------------"
    @board.each_with_index do |row, i|
      print "#{i}|"
      row.each do |cell|
        print "#{cell}|"
      end
      puts
      puts "-------------------"
    end
  end

  def play_game
    loop do
      print_board
      if @current_player == 'P'
        player_move
      else
        computer_move
      end

      if check_winner(@current_player)
        print_board
        puts "Congratulations! Player #{@current_player} wins!"
        break
      end

      if board_full?
        print_board
        puts "It's a draw!"
        break
      end

      switch_player
    end
  end

  def player_move
    loop do
      puts "Player #{@current_player}, enter your move (row column):"
      input = gets.chomp.split.map(&:to_i)
      row, col = input[0], input[1]
      
      if valid_move?(row, col)
        @board[row][col] = 'P'
        break
      else
        puts "Invalid move. Please try again."
      end
    end
  end

  # ✨ 修正されたコンピューターの動き ✨
  def computer_move
    puts "Computer is thinking..."
    best_move = find_best_move
    if best_move
      @board[best_move[:row]][best_move[:col]] = 'C'
      puts "Computer has made its move."
    else
      # もし最善手が見つからなければ、ランダムな場所に置く
      loop do
        row = rand(9)
        col = rand(9)
        if @board[row][col] == ' '
          @board[row][col] = 'C'
          break
        end
      end
      puts "Computer has made its move."
    end
  end

  def find_best_move
    best_score = -1
    best_move = nil

    (0..8).each do |r|
      (0..8).each do |c|
        if @board[r][c] == ' '
          # 石を仮に置いて評価する
          @board[r][c] = 'C'
          score = evaluate_move(r, c, 'C')
          
          # 相手のブロックを優先する
          @board[r][c] = 'P'
          opponent_score = evaluate_move(r, c, 'P')
          @board[r][c] = ' ' # 元に戻す
          
          final_score = score * 2 + opponent_score # 相手の脅威をより重視する
          
          if final_score > best_score
            best_score = final_score
            best_move = { row: r, col: c }
          end
        end
      end
    end
    best_move
  end

  def evaluate_move(row, col, player)
    score = 0
    directions = [[0, 1], [1, 0], [1, 1], [1, -1]]

    directions.each do |dr, dc|
      count = 1
      # 一方向に連続する石の数を数える
      (1..4).each do |i|
        r = row + i * dr
        c = col + i * dc
        break unless r.between?(0, 8) && c.between?(0, 8) && @board[r][c] == player
        count += 1
      end
      
      # 逆方向に連続する石の数を数える
      (1..4).each do |i|
        r = row - i * dr
        c = col - i * dc
        break unless r.between?(0, 8) && c.between?(0, 8) && @board[r][c] == player
        count += 1
      end
      
      # 連続する石の数に応じてスコアを加算
      case count
      when 2
        score += 1
      when 3
        score += 10
      when 4
        score += 100
      when 5
        score += 1000
      end
    end
    score
  end

  def valid_move?(row, col)
    row.between?(0, 8) && col.between?(0, 8) && @board[row][col] == ' '
  end

  def switch_player
    @current_player = (@current_player == 'P' ? 'C' : 'P')
  end

  def check_winner(player)
    (0..8).each do |i|
      (0..8).each do |j|
        if check_line(i, j, 0, 1, player) ||
           check_line(i, j, 1, 0, player) ||
           check_line(i, j, 1, 1, player) ||
           check_line(i, j, 1, -1, player)
          return true
        end
      end
    end
    false
  end

  def check_line(row, col, dr, dc, player)
    5.times do |i|
      r = row + i * dr
      c = col + i * dc
      return false unless r.between?(0, 8) && c.between?(0, 8) && @board[r][c] == player
    end
    true
  end

  def board_full?
    @board.flatten.none? { |cell| cell == ' ' }
  end
end

game = Gobang.new
game.play_game