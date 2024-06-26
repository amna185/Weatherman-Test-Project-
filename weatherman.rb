require_relative 'lib/weather_reports'

# def get_user_input
#   puts "Enter option (-e for annual report, -a for monthly average, -c for monthly chart):"
#   input = gets.chomp.split
#   return input[0], input[1], input[2]
# end

#variables initiliazed to nil
year = nil
month = nil
path = nil
option = {} #option hash to store information we will get from the user

# loop do
#   ARGV[0], ARGV[1], ARGV[2] = get_user_input

if ARGV[0] == '-e' #ARGV[] Is holding the users inputs , -e means an annual report is required
  year = ARGV[1].to_i #this will store the year and convert it to integer which is the second input by the user
  option[:type] = :year #this will store the year
  path = ARGV[2] #this is the third output from the user which is the path

elsif ARGV[0] == '-a'
  option[:type] = :month_average
  year, month = ARGV[1].split('/').map(&:to_i) #the expected output is 2019/09 which is converted to integer after splitting
  path = ARGV[2]
elsif ARGV[0] == '-c' #for the chart
  option[:type] = :month_chart
  year, month = ARGV[1].split('/').map(&:to_i)
  path = ARGV[2]

else
  puts "Invalid Option"
  exit(1) # Exit with an error code
end

weather_data = WeatherDataParser.read_weather_data(path)

case option[:type]
when :month_average
  ReportGenerator.generate_monthly_average_report(weather_data, year, month)
when :month_chart
  ReportGenerator.generate_monthly_chart(weather_data, year, month)
when :year
  ReportGenerator.generate_yearly_report(weather_data, year)
else
  puts "Unexpected option. Exiting."
  exit(1)
end
