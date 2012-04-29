require "pathname"

module Vagrant
  module Provisioners
    class Csistck < Base
      class Config < Vagrant::Config::Base
        attr_accessor :cookbook_path
        attr_accessor :provision_script
        attr_accessor :provision_path
        attr_accessor :debug

        def initialize
          @provision_path ||= "/tmp/csistck"
          @debug = false
        end

        def validate(env, errors)
          if !cookbook_path
            errors.add("Missing cookbook")
            expanded_path = Pathname.new(cookbook_path).expand_path(env.root_path)
            puts expanded_path
            if !expanded_path.directory?
              errors.add("Cookbook path does not exist")
            end
          end

          if !provision_script
            errors.add("Provision script not specified")
          end
        end
      end

      def self.config_class
        Config
      end
      
      def prepare
        env[:vm].config.vm.share_folder("csistck", config.provision_path,
          config.cookbook_path, :create => true)
      end

      def provision!
        command = "cd #{config.provision_path} && ./#{config.provision_script} --debug --verbose --repair"
        env[:vm].config.vm.share_folder("csistck", config.provision_path,
          config.cookbook_path, :create => true)

        env[:vm].channel.sudo(command) do |type, data|
          if [:stderr, :stdout].include?(type)
            color = type == :stdout ? :green : :red
            env[:ui].info(data.chomp, :color => color, :prefix => false)
          end
        end
      end
    end
  end
end
