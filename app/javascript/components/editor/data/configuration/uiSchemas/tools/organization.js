import CustomMultiSelectWidget from '../../../../components/widgets/CustomMultiSelectWidget'
import CustomTextWidget from '../../../../components/widgets/CustomTextWidget'

const organizationUiSchema = {
  Organizations: {
    items: {
      'ui:field': 'layout',
      'ui:controlled': {
        name: 'providers',
        map: {
          ShortName: 'short_name',
          LongName: 'long_name',
          URLValue: 'url'
        }
      },
      'ui:layout_grid': {
        'ui:row': [
          {
            'ui:col': {
              md: 12,
              children: [
                {
                  'ui:row': [
                    {
                      'ui:col': { md: 12, children: ['Roles'] }
                    }
                  ]
                },
                {
                  'ui:row': [
                    {
                      'ui:col': { controlName: 'short_name', md: 12, children: ['ShortName'] }
                    }
                  ]
                },
                {
                  'ui:row': [
                    {
                      'ui:col': { controlName: 'long_name', md: 12, children: ['LongName'] }
                    }
                  ]
                },
                {
                  'ui:row': [
                    {
                      'ui:col': { controlName: 'url', md: 12, children: ['URLValue'] }
                    }
                  ]
                }
              ]
            }
          }
        ]
      },
      Description: {
        'ui:widget': 'textarea'
      },
      ShortName: { 'ui:title': 'Short Name' },
      LongName: { 'ui:title': 'Long Name', 'ui:widget': CustomTextWidget },
      URLValue: { 'ui:title': 'URL value', 'ui:widget': CustomTextWidget },
      Roles: { 'ui:title': 'Roles', 'ui:widget': CustomMultiSelectWidget }
    }
  }
}
export default organizationUiSchema
