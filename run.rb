def env_check
    if (ENV['STEM'] != __dir__)
        abort "Bootenv and retry!"
    end
end
