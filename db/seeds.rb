# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

SKILLS_BY_GROUP = {
  dentist: [
    "Endodontics", "Restorative dentistry", "Pediatric dentistry", "Oral surgery",
    "Aligners / Invisalign", "Implantology", "Prosthodontics", "Periodontics"
  ],
  dental_hygienist: [
    "Periodontology", "Prevention", "Scaling and polishing", "Patient education",
    "Fluoride application", "Sealants"
  ],
  dental_assistant: [
    "Chairside assistance", "Sterilization", "Orthodontic assistance",
    "Prevention assistance", "X-rays", "Impression taking"
  ],
  front_office: [
    "Planning", "Phone handling", "Invoicing", "Patient communication",
    "Insurance administration", "Agenda management"
  ],
  practice_manager: [
    "Team management", "Scheduling", "HR", "Practice operations",
    "Budgeting", "Quality management"
  ],
  dental_technician: [
    "Prosthetics", "CAD/CAM", "Crown and bridge work", "Denture repair", "3D printing"
  ]
}.freeze

SKILLS_BY_GROUP.each do |group, names|
  names.each do |name|
    Skill.find_or_create_by!(name: name, function_group: group)
  end
end

LANGUAGES = %w[
  Dutch English German French Spanish Portuguese Polish Turkish Arabic Italian
].freeze

LANGUAGES.each { |name| Language.find_or_create_by!(name: name) }

if Rails.env.development?
  recruiter = User.find_or_create_by!(email_address: "recruiter@example.com") do |u|
    u.password = "password123"
    u.role = :recruiter
  end

  candidate_user = User.find_or_create_by!(email_address: "candidate@example.com") do |u|
    u.password = "password123"
    u.role = :candidate
  end

  puts "Seeded #{Skill.count} skills, #{Language.count} languages."
  puts "Demo recruiter: #{recruiter.email_address} / password123"
  puts "Demo candidate: #{candidate_user.email_address} / password123"
end
