class String

  COLORS = {:red => 31, :green => 32, :yellow => 33, :blue => 36, :white => 37}

  COLORS.keys.each do |color|
    define_method color do
      colorize color
    end
  end

private

  def colorize(color)
    color = COLORS[color]
    "\e[1m\e[#{color}m#{self}\e[0m"
  end

end
