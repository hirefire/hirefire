# encoding: utf-8

module HireFire
  class Logger

    ##
    # Outputs a messages to the console
    #
    # @param [String] string prints a string to the console (green color)
    # @return [nil]
    def self.message(string)
      puts loggify(string, :green)
    end

    ##
    # Outputs an error to the console
    #
    # @param [String] string prints a string to the console (red color)
    # @return [nil]
    def self.error(string)
      puts loggify(string, :red)
    end

    ##
    # Outputs a notice to the console
    #
    # @param [String] string prints a string to the console (yellow color)
    # @return [nil]
    def self.warn(string)
      puts loggify(string, :yellow)
    end

    ##
    # Outputs the data as if it were a regular 'puts' command
    #
    # @param [String] string prints a string to the console (standard color)
    # @return [nil]
    def self.normal(string)
      puts string
    end

    ##
    # Builds the string in a log format with the date/time, the type (colorized)
    # based on whether it's a message, notice or error, and the message itself.
    #
    # @param [String] string the string to print to the console
    # @param [Symbol, false] color the color to print the string in
    # @return [String] the log-like formatted string
    def self.loggify(string, color = false)
      return "[#{time}][HireFire] #{string}" unless color
      "[#{time}][#{send(color, 'HireFire')}] #{string}"
    end

    ##
    # @return [Time] the time in [YYYY-MM-DD HH:MM:SS] format
    def self.time
      Time.now.strftime("%Y-%m-%d %H:%M:%S")
    end

    ##
    # Invokes the #colorize method with the provided string
    # and the color code "32" (for green)
    #
    # @param [String] string
    # @return [String] the provided string in special tags to color it green in the console
    def self.green(string)
      colorize(string, 32)
    end

    ##
    # Invokes the #colorize method with the provided string
    # and the color code "33" (for yellow)
    #
    # @param [String] string
    # @return [String] the provided string in special tags to color it yellow in the console
    def self.yellow(string)
      colorize(string, 33)
    end

    ##
    # Invokes the #colorize method the with provided string
    # and the color code "31" (for red)
    def self.red(string)
      colorize(string, 31)
    end

    ##
    # Wraps the provided string in colorizing tags to provide
    # easier to view output to the client
    #
    # @param [String] string
    # @return [String] the provided string in special tags to color it red in the console
    def self.colorize(string, code)
      "\e[#{code}m#{string}\e[0m"
    end

  end
end
