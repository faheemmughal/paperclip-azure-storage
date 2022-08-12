# Paperclip Azure Storage
## Description
`paperclip-azure-storage` is a [paperclip](https://github.com/thoughtbot/paperclip) adapter for azure storage.

The difference between this and other azure adapter, such as [paperclip-azure](https://github.com/supportify/paperclip-azure),

was the ability to use [service principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals)
as the authentication method.

## Getting Started
1. Add `paperclip-azure-storage` on `Gemfile`
```ruby
gem 'paperclip-azure-storage'
```
2. Configure `paperclip`
```ruby
require 'paperclip-azure-storage'

Paperclip::DataUriAdapter.register

Paperclip::Attachment.default_options[:storage] = :azure_storage
Paperclip::Attachment.default_options[:tenant_id] = 'c881ddef-bf33-4574-a43b-1876a94c940a'
Paperclip::Attachment.default_options[:resource] = 'https://mystorage.blob.core.windows.net'
Paperclip::Attachment.default_options[:storage_name] = 'mystorage'
Paperclip::Attachment.default_options[:container] = 'mycontainer'
```
3. Upload & access your image
```ruby
image_content = '<some-image>'
model = model_class.create!(image: image_content) # upload image to azure
model.image.azure_url # get azure image url
```
