#   Developer:  Fede Arbelaez
#   Date:       05-18-2018
#   Problem:    Some clients have their contract based on enrrollments and if they don't use terms it's difficult 
#               to get that number of enrollemtns per year   
#   Description: This script will read a enrollments CSV file exported from the root account as a provisioning
#                report and getting the students IDs, then calling the enrollment API calls to get: 
#                user_id,
#                course_id, 
#                enrollment_id,
#                enrollment_type,
#                created_at, 
#                updated_at,
#                enrollment_state, 
#                last_activity_at


#Import gems 
require 'csv'
require 'date'
require 'typhoeus'
require 'json'

#Instance of Canvas 
canvas_url      = '{{Canvas URL}}' 
canvas_token    = '{{Canvas token}}' 
current_date    = DateTime.now

#Provisioning report with all the users and the file where the new report will be created 
current_users   = '{{Provisioning report of enrollments}}' 
output_file     = "/{{local path to safe the document}}/enrollments_#{current_date}.csv"

#Timer to validate interactions and time spent 
enrollments_total = 0
time_start = Time.now

#Create headers into the output file
CSV.open(output_file, 'wb') do |csv|
    csv << ["user_id",
            "course_id", 
            "enrollment_id",
            "enrollment_type",
            "created_at", 
            "updated_at",
            "enrollment_state", 
            "last_activity_at"]
end

CSV.foreach(current_users,headers:true) do |row|
    
    user_id = row['canvas_user_id']
    puts "User ID #{user_id}"
    puts "#{canvas_url}/api/v1/users/#{user_id}/enrollments"

    enrollments_user = Typhoeus::Request.new(
        "#{canvas_url}/api/v1/users/#{user_id}/enrollments",
        method: :get,
        headers: { authorization: "Bearer #{canvas_token}" },
        params: {
        }
    )

    #puts "cURL ready #{enrollment_per_user}"
    puts "Before running the cURL per user"

    enrollments_user.on_complete do |response|
        
        
        if response.code == 200
            
            data = JSON.parse(response.body)
            #puts data

            data.each do |enroll_info|                      # loop over each user's data stored in the array
                user_id = enroll_info['user_id']            # reference the id field in the array and store as the user_id
                course_id = enroll_info['course_id']
                enrollment_id = enroll_info['id']
                enrollment_type = enroll_info['type']
                created_at = enroll_info['created_at']
                updated_at = enroll_info['updated_at']
                enrollment_state = enroll_info['enrollment_state']
                last_activity_at = enroll_info['last_activity_at']

                CSV.open(output_file, 'a') do |csv|
                    csv << [user_id, 
                            course_id, 
                            enrollment_id,
                            enrollment_type,
                            created_at, 
                            updated_at,
                            enrollment_state, 
                            last_activity_at]
                end
                enrollments_total += 1
            end 
            
        else
            puts "Something went wrong! Response code was #{response.code}"
        end
    end

    enrollments_user.run 
    #puts "Exit"
    
end

time_end = Time.now
total_time = time_end - time_start
puts "#{enrollments_total} enrollments"
puts "The script took #{total_time} seconds to run"
