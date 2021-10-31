require './spec/spec_helper'

class MockPaperclip < ActiveRecord::Base
  include Paperclip::Glue

  has_attached_file(
    :image,
    path: 'img/missions/:reversed_path/:style/:filename',
    url: 'img/missions/:reversed_path/:style/:filename',
    storage: :azure_storage,
    tenant_id: 'tenant-id',
    client_id: 'client-id',
    resource: 'resource',
    storage_name: 'storage-name',
    container: 'container'
  )
  validates_attachment_content_type :image, content_type: /\Aimage/
end

describe 'AzureStorage' do
  before(:all, 'create mock table') do
    MockPaperclip.connection.create_table(MockPaperclip.table_name, force: true) do |table|
      table.column :image_content_type, :string
      table.column :image_file_name, :string
      table.column :image_file_size, :integer
      table.column :image_updated_at, :datetime
      table.column :image_fingerprint, :string
    end
  end

  before 'mock login' do
    method = :post
    uri = %r{https://login.microsoftonline.com/.+/oauth2/token}
    status = 200
    body = {
      token_type: 'Bearer',
      expires_in: '3599',
      ext_expires_in: '3599',
      expires_on: '1634195094',
      not_before: '1634191194',
      resource: 'resource',
      access_token: 'access_token'
    }.to_json
    headers = { 'Content-Type': 'application/json' }

    stub_request(method, uri).to_return(status: status, body: body, headers: headers)
  end

  before 'mock create_block_blob' do
    method = :put
    uri = %r{https://[a-z-]+.blob.core.windows.net/container/.+}
    status = 201
    body = ''
    headers = {}

    stub_request(method, uri).to_return(status: status, body: body, headers: headers)
  end

  before 'mock list_blobs' do
    method = :get
    uri = %r{https://[a-z-]+.blob.core.windows.net/container\?}
    status = 200
    body =     File.read('./spec/fixtures/list_blobs.xml')

    headers = {}

    stub_request(method, uri).to_return(status: status, body: body, headers: headers)
  end

  before 'mock get_blob' do
    method = :get
    uri = %r{https://storage-name.blob.core.windows.net/container/.+}
    status = 200
    body = image
    headers = {}

    stub_request(method, uri).to_return(status: status, body: body, headers: headers)
  end

  before 'mock delete_blob' do
    method = :delete
    uri = %r{https://[a-z-]+.blob.core.windows.net/container/.+}
    status = 202
    body = ''
    headers = {}

    stub_request(method, uri).to_return(status: status, body: body, headers: headers)
  end

  let(:image) { 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7' }

  describe 'upload image' do
    subject { MockPaperclip.create(image: image) }

    it 'success' do
      expect { subject }.not_to raise_error
    end

    describe '500 response' do
      before 'mock create_block_blob' do
        method = :put
        uri = %r{https://[a-z-]+.blob.core.windows.net/container/.+}
        status = 500
        body = ''
        headers = {}

        stub_request(method, uri).to_return(status: status, body: body, headers: headers)
      end

      it 'raise error' do
        expect { subject }.to raise_error(Azure::Core::Http::HTTPError)
      end
    end
  end

  describe 'delete image' do
    let(:model) { MockPaperclip.create(image: image) }

    subject { model.image.destroy }

    it 'success' do
      expect { subject }.not_to raise_error
    end
  end

  describe 'download image' do
    let(:model) { MockPaperclip.create(image: image) }

    subject { model.image.copy_to_local_file('original', "/tmp/#{SecureRandom.hex(4)}") }

    it 'success' do
      expect { subject }.not_to raise_error
    end
  end
end