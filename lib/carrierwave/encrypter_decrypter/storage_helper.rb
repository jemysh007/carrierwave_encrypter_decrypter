module Carrierwave
  module EncrypterDecrypter
    module StorageHelper
      class << self
        def fog_storage?(uploader)
          defined?(CarrierWave::Storage::Fog) &&
            uploader.class.storage == CarrierWave::Storage::Fog
        rescue
          false
        end

        def fog_read(uploader, key)
          file = fog_directory(uploader).files.get(key)
          raise "File not found in fog storage: #{key}" unless file
          file.body
        end

        def fog_write(uploader, key, data)
          fog_directory(uploader).files.create(
            key: key,
            body: data,
            public: fog_public(uploader)
          )
        end

        def fog_delete(uploader, key)
          file = fog_directory(uploader).files.get(key)
          file.destroy if file
        end

        private

        def fog_connection(uploader)
          ::Fog::Storage.new(uploader.class.fog_credentials)
        end

        def fog_directory(uploader)
          fog_connection(uploader).directories.get(uploader.class.fog_directory)
        end

        def fog_public(uploader)
          uploader.class.fog_public
        rescue
          false
        end
      end
    end
  end
end
