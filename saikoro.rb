puts "=== サイコロバトル ==="
player_score = 0
enemy_score = 0

3.times do |round|
  puts "\n第#{round + 1}ラウンド！Enterキーでサイコロを振る"
  gets
  player = rand(1..6)
  enemy = rand(1..6)

  puts "あなたの出目: #{player}"
  puts "敵の出目: #{enemy}"

  if player > enemy
    puts "あなたの勝ち！"
    player_score += 1
  elsif player < enemy
    puts "敵の勝ち！"
    enemy_score += 1
  else
    puts "引き分け！"
  end
end

puts "\n=== 結果発表 ==="
if player_score > enemy_score
  puts "🎉 あなたの勝利！"
elsif player_score < enemy_score
  puts "💀 敵の勝利…"
else
  puts "😎 引き分け！"
end
