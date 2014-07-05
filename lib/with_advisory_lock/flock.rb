require 'fileutils'

module WithAdvisoryLock
  class Flock < Base

    def filename
      @filename ||= begin
        safe = @lock_name.to_s.gsub(/[^a-z0-9]/i, '')
        fn = ".lock-#{safe}-#{stable_hashcode(@lock_name)}"
        # Let the user specify a directory besides CWD.
        ENV['FLOCK_DIR'] ? File.expand_path(fn, ENV['FLOCK_DIR']) : fn
      end
    end

    def file_io
      @file_io ||= begin
        FileUtils.touch(filename)
        File.open(filename, 'r+')
      end
    end

    def try_lock
      0 == file_io.flock(File::LOCK_EX|File::LOCK_NB)
    end

    def advisory_lock_exists?(name)
      acquired = true
      yield_with_lock(0) { acquired = false }
      acquired
    end

    def release_lock
      0 == file_io.flock(File::LOCK_UN)
    end
  end
end
