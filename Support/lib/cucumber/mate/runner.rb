require File.join(File.dirname(__FILE__), %w[.. mate])
require File.join(File.dirname(__FILE__), 'files')

module Cucumber
  module Mate

    class Runner
      CUCUMBER_BIN = %x{which cucumber}.chomp
      RUBY_BIN = ENV['TM_RUBY'] || %x{which ruby}.chomp
      RAKE_BIN = %x{which rake}.chomp
      
      def initialize(output, project_directory, full_file_path, cucumber_bin = nil, cucumber_opts=nil)
        @file = Files::Base.create_from_file_path(full_file_path) unless full_file_path.nil? #Santosh
        @output = output
        @project_directory = project_directory
        @filename_opts = ""
        @cucumber_bin = cucumber_bin || CUCUMBER_BIN
        @cucumber_opts = cucumber_opts || "--format=html"
        if full_file_path #Santosh
          puts "In if #{full_file_path}"
          @cucumber_opts << " --profile=#{@file.profile}" if @file.profile
        end #Santosh
        
      end

      def run_scenario(line_number)
        @filename_opts << ":#{line_number}"
        run
      end

      def run_feature
        run
      end
      
      #Santosh
      def re_run_feature
        re_run
      end
      
      
      def autoformat_feature
        in_project_dir do
          Kernel.system("#{cucumber_cmd} --autoformat . #{@file.relative_path}")
        end
      end
      
      
      #Santosh
      def re_run
        last_full_command = nil
        if File.exist?('/tmp/last_command')
          last_full_command = IO.readlines('/tmp/last_command')[0] 
          @project_directory = IO.readlines('/tmp/last_project_directory')[0]
        end
      
        in_project_dir do
          @output << Kernel.system(last_full_command) unless last_full_command.nil?
        end
        
      end
      
      


    protected

      def run
        argv = []
        if @file.rake_task
          command = RAKE_BIN
          argv << "FEATURE=#{@file.full_file_path}"
          argv << %Q{CUCUMBER_OPTS="#{@cucumber_opts}"}
        else
          command = cucumber_cmd
          argv << "#{@file.full_file_path}#{@filename_opts}"
          argv << @cucumber_opts
        end
        
        #Santosh
        @last_project_directory = File.new('/tmp/last_project_directory', "w")
        @last_project_directory.write(@project_directory)
        @last_project_directory.close
        
        in_project_dir do
          @output << %Q{Running: #{full_command = "#{RUBY_BIN} #{command} #{@file.rake_task} #{argv.join(' ')}"} \n}
          
          #Santosh
          @last_command_file = File.new('/tmp/last_command', "w")
          @last_command_file.write("#{full_command}\n")
          @last_command_file.close
          
          
          @output << Kernel.system(full_command)
        end
      end
      
      def cucumber_cmd
        File.exists?(script = "#{@project_directory}/script/cucumber") ? script : @cucumber_bin
      end

      def in_project_dir(&block)
        Dir.chdir(@project_directory, &block)
      end

    end

  end
end
