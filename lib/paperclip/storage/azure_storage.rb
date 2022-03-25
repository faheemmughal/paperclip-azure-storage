module Paperclip
  module Storage
    module AzureStorage
      def self.extended(_base)
        require 'azure/storage/blob'
        require 'azure/storage/common'
      end

      def exists?(style_name = default_style)
        container = @options[:container]
        storage_client.list_blobs(
          container,
          prefix: path(style_name),
          max_results: 1,
          timeout: 60
        ).present?
      end

      def flush_writes
        container = @options[:container]
        @queued_for_write.each do |style_name, file|
          storage_client.create_block_blob(
            container,
            path(style_name),
            file.read,
            timeout: 60,
            content_type: file.content_type,
            content_length: file.size
          )
        end

        after_flush_writes
        @queued_for_write = {}
      end

      def flush_deletes
        container = @options[:container]
        @queued_for_delete.each { |path| storage_client.delete_blob(container, path, timeout: 60) }

        @queued_for_delete = []
      end

      def copy_to_local_file(style, local_dest_path)
        container = @options[:container]
        _blob, content = storage_client.get_blob(container, path(style), timeout: 60)
        ::File.open(local_dest_path, 'wb') { |local_file| local_file.write(content) }
      end

      def azure_url(style_name = default_style)
        "#{@options[:resource]}/#{@options[:container]}/#{path(style_name)}".squeeze('/')
      end

      def expiring_url(time = 3600, style_name = default_style)
        if path(style_name)
          storage_client # refreshes token if expired
          shared_access_signature = ::Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(
            @options[:storage_name],
            "",
            get_user_delegation_key
          )
          puts "Azure url: #{azure_url(style_name)}"
          shared_access_signature.signed_uri(
            URI(azure_url(style_name)),
            false,
            service: 'b',
            resource: 'b',
            permissions: 'r',
          )
        else
          azure_url(style_name)
        end
      end

      def expiring_url2(time = 3600, style_name = default_style)
        if path(style_name)
          storage_client # refreshes token if expired
          shared_access_signature = ::Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(
            @options[:storage_name],
            "",
            get_user_delegation_key
          )
          shared_access_signature.signed_uri(
            azure_url(style_name),
            false,
            service: 'b',
            resource: 'b',
            permissions: 'r',
          )
        else
          azure_url(style_name)
        end
      end

      def expiring_path(time = 3600, style_name = default_style)
        if path(style_name)
          storage_client # refreshes token if expired
          shared_access_signature = ::Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(
            @options[:storage_name],
            "",
            get_user_delegation_key
          )
          shared_access_signature.signed_uri(
            storage_client.generate_uri("#{@options[:container]}/#{path(style_name)}".squeeze('/')),
            false,
            service: 'b',
            resource: 'b',
            permissions: 'r',
          )
        else
          azure_url(style_name)
        end
      end

      def expiring_path2(time = 3600, style_name = default_style)
        if path(style_name)
          storage_client # refreshes token if expired
          shared_access_signature = ::Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(
            @options[:storage_name],
            "",
            get_user_delegation_key
          )
          shared_access_signature.signed_uri(
            URI("#{@options[:container]}/#{path(style_name)}".squeeze('/')),
            false,
            service: 'b',
            resource: 'b',
            permissions: 'r',
          )
        else
          azure_url(style_name)
        end
      end

      private

      def storage_client
        renew_expired_token
        @storage_client ||= create_storage_client
      end

      def get_user_delegation_key
        renew_expired_user_delegation_key
        @user_delegation_key ||= get_fresh_user_delegation_key
      end

      def renew_expired_token
        expired = @expires_on.present? && Time.now.to_i >= @expires_on.to_i
        return unless expired

        @access_token, @expires_on = create_access_token
        @token_credential.renew_token(@access_token)
      end

      def renew_expired_user_delegation_key
        expired = @delegation_key_expires_on.present? && @delegation_key_expires_on < 1.hour.from_now
        return unless expired

        @user_delegation_key = get_fresh_user_delegation_key
      end

      def get_fresh_user_delegation_key
        @delegation_key_expires_on = 1.day.from_now
        storage_client.get_user_delegation_key(
          Time.now,
          @delegation_key_expires_on
        )
      end

      def create_storage_client
        storage_name = @options[:storage_name]
        @access_token, @expires_on = create_access_token
        @token_credential = ::Azure::Storage::Common::Core::TokenCredential.new(@access_token)
        token_signer = ::Azure::Storage::Common::Core::Auth::TokenSigner.new(@token_credential)
        service = ::Azure::Storage::Blob::BlobService.new(storage_account_name: storage_name, signer: token_signer)
        service.with_filter Azure::Core::Http::DebugFilter.new
        service.with_filter Azure::Storage::Common::Core::Filter::ExponentialRetryPolicyFilter.new
        service
      end

      def create_access_token
        tenant_id = @options[:tenant_id]
        client_id = @options[:client_id]
        client_secret = @options[:client_secret]
        resource = @options[:resource]
        grant_type = 'client_credentials'

        requested_at = Time.now.to_i
        response = faraday_client.post("#{tenant_id}/oauth2/token") do |request|
          request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
          request.headers['Accept'] = 'application/json'
          request_payload = {
            client_id: client_id,
            client_secret: client_secret,
            resource: resource,
            grant_type: grant_type
          }
          request.body = URI.encode_www_form(request_payload)
        end

        access_token = response.body['access_token']
        expires_on = requested_at + response.body['expires_in'].to_i

        [access_token, expires_on]
      end

      def faraday_client
        @faraday_client ||= Faraday.new('https://login.microsoftonline.com') do |client|
          client.request :retry
          client.response :json
          client.response :raise_error
          client.adapter :net_http
        end
      end
    end
  end
end
