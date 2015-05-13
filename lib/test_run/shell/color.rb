module TestLauncher
  module Shell
    module Color
      CODES = {
        red: 31,
        green: 32,
        yellow: 33,
        pink: 35,
      }.freeze

      CODES.each do |color, code|
        self.send(:define_method, color) do |string|
          colorize(string, code)
        end
      end

      private

      # colorization
      def colorize(string, color_code)
        "\e[#{color_code}m#{string}\e[0m"
      end

    end
  end
end
