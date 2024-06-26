require 'csv'
require 'colorize'

class WeatherDataParser
  def self.read_weather_data(path)
    weather_data = [] #an empty array to store the data

    Dir.foreach(path) do |filename|
      next if filename == '.' || filename == '..' #to exclude the parent files or root files
      file_path = File.join(path, filename)
      folder_name = File.dirname(file_path).split('/')[-1].split('_')[0]

      total_lines = File.foreach(file_path).count

      line_number = 0
      CSV.foreach(file_path, headers: true, skip_blanks: true) do |row|
        line_number += 1
        next if folder_name == 'lahore' && line_number == total_lines

        date = case folder_name
        when 'Dubai'
          row['GST']
        when 'lahore', 'Murree'
          row['PKT']
        else
          nil
        end
        max_humidity = row['Max Humidity']
        max_temp = row['Max TemperatureC']
        min_temp = row['Min TemperatureC']


        max_temp_value = max_temp&.to_i
        min_temp_value = min_temp&.to_i
        max_humidity_value = max_humidity.nil? ? '' : max_humidity.to_i

        # puts "Raw date value: #{date}" # Debug print


        begin
          if date.nil? || date.empty?
            raise Date::Error, "Date is empty"
          end
          date_value = Date.parse(date)
          weather_data << {
            date: date_value.to_s,
            max_humidity: max_humidity_value,
            max_temperature: max_temp_value,
            min_temperature: min_temp_value
          }
        rescue Date::Error
          weather_data << {
            date: nil,
            max_humidity: max_humidity_value,
            max_temperature: max_temp,
            min_temperature: min_temp
          }
        end
      end
    end

    weather_data
  end
end

class ReportGenerator
  def self.generate_yearly_report(data, year)
    year_data = data.reject do |entry|
      entry_date = entry[:date]
      if entry_date.nil?
        true
      else
        begin
          Date.parse(entry_date).year != year
        rescue Date::Error
          true
        end
      end
    end

    highest_temp = nil
    highest_temp_day = nil
    lowest_temp = nil
    lowest_temp_day = nil
    highest_humidity = nil
    highest_humidity_day = nil

    year_data.each do |row|
      date_str = row[:date]
      next if date_str.nil? || date_str.empty?

      begin
        date = Date.parse(date_str)
      rescue ArgumentError => e
        puts "Error parsing date '#{date_str}': #{e.message}"
        next
      end

      max_temp = row[:max_temperature].to_i
      min_temp = row[:min_temperature].to_i
      humidity = row[:max_humidity].to_i

      if highest_temp.nil? || max_temp > highest_temp
        highest_temp = max_temp
        highest_temp_day = date.strftime("%B %d")
      end

      if lowest_temp.nil? || min_temp < lowest_temp
        lowest_temp = min_temp
        lowest_temp_day = date.strftime("%B %d")
      end

      if highest_humidity.nil? || humidity > highest_humidity
        highest_humidity = humidity
        highest_humidity_day = date.strftime("%B %d")
      end
    end

    if highest_temp.nil? && lowest_temp.nil? && highest_humidity.nil?
      puts "No data available for #{year}"
    else
      puts "Yearly Report for #{year}:"
      puts "Highest Temperature: #{highest_temp}C on #{highest_temp_day}"
      puts "Lowest Temperature: #{lowest_temp}C on #{lowest_temp_day}"
      puts "Highest Humidity: #{highest_humidity}% on #{highest_humidity_day}"
    end
  end

  def self.generate_monthly_average_report(data, year, month)
    total_high_temp = 0
    total_low_temp = 0
    total_humidity = 0
    count = 0

    data.each do |row|
      date_str = row[:date]
      next if date_str.nil?

      begin
        date = Date.parse(date_str)
      rescue ArgumentError => e
        puts "Error parsing date '#{date_str}': #{e.message}"
        next
      end

      next unless date.year == year && date.month == month

      total_high_temp += row[:max_temperature].to_i
      total_low_temp += row[:min_temperature].to_i
      total_humidity += row[:max_humidity].to_i
      count += 1
    end

    if count > 0
      puts "Monthly Average Report for #{Date::MONTHNAMES[month]} #{year}:"
      puts "Highest Average Temperature: #{total_high_temp / count}C"
      puts "Lowest Average Temperature: #{total_low_temp / count}C"
      puts "Average Humidity: #{total_humidity / count}%"
    else
      puts "No data available for #{Date::MONTHNAMES[month]} #{year}"
    end
  end

  def self.generate_monthly_chart(data, year, month)
    chart_data = {}

    data.each do |row|
      date_str = row[:date]
      next if date_str.nil?

      begin
        date = Date.parse(date_str)
      rescue ArgumentError => e
        puts "Error parsing date '#{date_str}': #{e.message}"
        next
      end

      next unless date.year == year && date.month == month

      day = date.day
      max_temp = row[:max_temperature].to_i
      min_temp = row[:min_temperature].to_i

      chart_data[day] ||= {}
      chart_data[day][:max] = max_temp
      chart_data[day][:min] = min_temp
    end

    puts "#{Date::MONTHNAMES[month]} #{year}"

    chart_data.keys.sort.each do |day|
      max_bars = '+' * chart_data[day][:max]
      min_bars = '+' * chart_data[day][:min]
      puts "#{day.to_s.rjust(2)} #{max_bars.red} #{chart_data[day][:max]}C"
      puts "#{day.to_s.rjust(2)} #{min_bars.blue} #{chart_data[day][:min]}C"
    end
  end
end

class WeatherAnalyzer
  def self.process_options(options, files_folder)
    weather_data = WeatherDataParser.read_weather_data(files_folder)

    case
    when options[:year] && !options[:month]
      ReportGenerator.generate_yearly_report(weather_data, options[:year])
    when options[:year] && options[:month] && !options[:mode]
      ReportGenerator.generate_monthly_average_report(weather_data, options[:year], options[:month])
    when options[:year] && options[:month] && options[:mode] == :chart
      ReportGenerator.generate_monthly_chart(weather_data, options[:year], options[:month])
    end
  end
end
