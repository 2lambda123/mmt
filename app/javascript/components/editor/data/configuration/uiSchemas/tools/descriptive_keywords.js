const descriptiveKeywordsUiSchema = {

  'ui:field': 'layout',
  'ui:layout_grid': {
    'ui:row': [
      {
        'ui:col': {
          md: 12,
          children: [
            {
              'ui:row': [
                { 'ui:col': { md: 12, children: ['ToolKeywords'] } }
              ]
            },
            {
              'ui:row': [
                { 'ui:col': { md: 12, children: ['AncillaryKeywords'] } }
              ]
            }

          ]
        }
      }
    ]
  },
  ToolKeywords: {
    'ui:title': 'Tool Keyword',
    'ui:field': 'keywordPicker'
  },

  AncillaryKeywords: {
    'ui:title': 'Ancillary Keywords',
    'ui:default': '',
    items: {
      'ui:title': 'Ancillary Keyword'
    }
  }

}
export default descriptiveKeywordsUiSchema
