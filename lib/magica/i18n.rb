require 'i18n'

# rubocop:disable Metrics/LineLength
# rubocop:disable Style/FormatStringToken
en = {
  not_init_project: 'The project is not initialize, please run "magica init" before start use it',
  unknow_toolchain: 'Unknow %{toolchain} toolchain',
  unknow_build: 'Unknow %{build} build'
}
# rubocop:enable Metrics/LineLength

I18n.backend.store_translations(:en, magica: en)

if I18n.respond_to?(:enforce_available_locales=)
  I18n.enforce_available_locales = true
end
