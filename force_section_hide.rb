

require 'csv'
require 'typhoeus'
require 'json'
#------------------Replace these values-----------------------------#

access_token = ''
url = 'https://something.instructure.com'  			#Enter the full URL to the domain you want to merge files. This is the full Canvas URL exculding the https://
csv_file = 'force_section_hide.csv' 					#Enter the full path to the file. /Users/XXXXXX/Path/To/File.csv

#-------------------Do not edit below this line---------------------#
unless Typhoeus.get(url).code == 200 || 302
	raise 'Unable to run script, please check token, and/or URL.'
end

unless File.exists?(csv_file)
	raise "Can't locate the CSV file."
end

hydra = Typhoeus::Hydra.new(max_concurrency: 10)

CSV.foreach(csv_file, {:headers => true}) do |row|

	api_call = "#{url}/api/v1/sections/#{row['canvas_section_id']}/enrollments"
	canvas_api = Typhoeus::Request.new(api_call,
										method: :post,
										params: {'enrollment[user_id]' => row['canvas_user_id'],
															'enrollment[role_id]' => row['role_id'],
															'enrollment[enrollment_state]' => 'active',
															'enrollment[limit_privileges_to_course_section]'=>'true'},
										headers: { "Authorization" => "Bearer #{access_token}" })
		canvas_api.on_complete do |response|
			if response.code == 200
				puts "Enrolled user #{row['canvas_user_id']} into section #{row['canvas_section_id']} as a #{row['role']} with other sections hidden"
			else
				puts "Unable to enroll user #{row['canvas_user_id']} into section #{row['canvas_section_id']} as a #{row['role']}. (Code: #{response.code}) #{response.body}"

			end
		end
	hydra.queue(canvas_api)
end
hydra.run

puts 'Successfully fixed enrolled users.'
