module Carrierwave
  module EncrypterDecrypter
    module StorageHelper
      class << self
        def remote_storage?(uploader)
          fog_storage?(uploader) || aws_storage?(uploader)
        end

        def fog_storage?(uploader)
          defined?(CarrierWave::Storage::Fog) &&
            storage_class(uploader) == CarrierWave::Storage::Fog
        rescue
          false
        end

        def aws_storage?(uploader)
          defined?(CarrierWave::Storage::AWS) &&
            storage_class(uploader) == CarrierWave::Storage::AWS
        rescue
          false
        end

        def read(uploader, key)
          if fog_storage?(uploader)
            file = fog_directory(uploader).files.get(key)
            raise "File not found in fog storage: #{key}" unless file
            file.body
          elsif aws_storage?(uploader)
            aws_object(uploader, key).get.body.read
          else
            raise "Unsupported remote storage for read: #{storage_class(uploader)}"
          end
        end

        def write(uploader, key, data)
          if fog_storage?(uploader)
            fog_directory(uploader).files.create(
              key: key,
              body: data,
              public: fog_public(uploader)
            )
          elsif aws_storage?(uploader)
            aws_object(uploader, key).put({ body: data }.merge(aws_write_options(uploader)))
          else
            raise "Unsupported remote storage for write: #{storage_class(uploader)}"
          end
        end

        def delete(uploader, key)
          if fog_storage?(uploader)
            file = fog_directory(uploader).files.get(key)
            file.destroy if file
          elsif aws_storage?(uploader)
            aws_object(uploader, key).delete
          else
            raise "Unsupported remote storage for delete: #{storage_class(uploader)}"
          end
        end

        private

        def storage_class(uploader)
          uploader.class.storage
        end

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

        def aws_object(uploader, key)
          raise "AWS SDK not loaded" unless defined?(::Aws::S3::Object)
          file = uploader.file
          raise "Uploader file is unavailable for AWS storage" unless file

          object = file.file
          unless object.is_a?(::Aws::S3::Object)
            raise "Unsupported AWS file object: #{object.class}"
          end

          object.bucket.object(key)
        end

        def aws_write_options(uploader)
          return {} unless uploader.class.respond_to?(:aws_acl)
          acl = uploader.class.aws_acl
          acl.nil? ? {} : { acl: acl }
        rescue
          {}
        end
      end
    end
  end
end
