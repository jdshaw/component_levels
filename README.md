Component Levels
================

ArchivesSpace plugin surface the Archival Object `level` as a facet in the general and advanced search and also in the component display strings.

## Installing it

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     # If you have other plugins loaded, just add 'container_management' to
     # the list
     AppConfig[:plugins] = ['local', 'other_plugins', 'component_levels']

And then clone the `component_levels` repository into your
ArchivesSpace plugins directory.  For example:

     cd /path/to/your/archivesspace/plugins
     git clone https://github.com/hudmol/component_levels.git component_levels

