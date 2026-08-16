def env_check(dir)
    stem = ENV['STEM'] || ""
    if stem == "" || (File.expand_path(stem) != File.expand_path(dir))
        puts "\e[31mFAILED\e[0m -> Bootenv check"
        puts "Bootenv and retry!"
        true
    else
        puts "\e[32mPASSED\e[0m -> Bootenv check"
        false
    end
end