import Draft from '../../model/Draft'
import { MetadataService } from '../MetadataService'

describe('Testing MetadataService', () => {
  async function mockFetch(url) {
    switch (url) {
      case '/api/tool_drafts/1': {
        return {
          ok: true,
          status: 200,
          json: async () => ({
            draft: {
              Name: 'a name', LongName: 'a long name', Version: '1', Type: 'Web Portal'
            },
            id: 50,
            user_id: 9
          })
        }
      }
      case '/api/tool_drafts/101': {
        return {
          ok: false,
          status: 404,
          json: async () => ({
            error: 'Error found'
          })
        }
      }
      case '/api/tool_drafts/55': {
        return {
          ok: true,
          status: 200,
          json: async () => ({
            id: 55
          })
        }
      }
      case '/api/tool_drafts/200': {
        return {
          ok: false,
          status: 404,
          json: async () => ({
            error: 'Error found'
          })
        }
      }
      case '/api/tool_drafts/': {
        return {
          ok: true,
          status: 200,
          json: async () => ({
            id: 12
          })
        }
      }
      case '/api/cmr_keywords/science_keywords': {
        return {
          ok: true,
          status: 200,
          json: async () => ({
            Name: 'a name', LongName: 'a long name', Version: '1', Type: 'Web Portal'
          })
        }
      }
      case '/api/cmr_keywords/science': {
        return {
          ok: false,
          status: 404,
          json: async () => ({
            error: 'Error found'
          })
        }
      }
      default: {
        console.log(`Unhandled request: ${url}`)
        return undefined
      }
    }
  }
  const OLD_ENV = process.env

  beforeEach(() => {
    process.env = { ...OLD_ENV }
    window.fetch.mockImplementation(mockFetch)
  })

  afterEach(() => {
    process.env = OLD_ENV
  })

  beforeAll(() => jest.spyOn(window, 'fetch'))

  test('fetch draft', async () => {
    const metadataService = new MetadataService('test_token', 'tool_drafts', 'test_user', 'provider')
    metadataService.fetchDraft(1).then((draft) => {
      expect(draft.json.Name).toEqual('a name')
      expect(draft.json.LongName).toEqual('a long name')
      expect(draft.apiId).toEqual(50)
    })
    metadataService.fetchDraft(101).then((draft) => {
      console.log(draft)
    }).catch((error) => {
      expect(error.message).toEqual('Error code: 404')
    })
  })

  test('save draft', async () => {
    const metadataService = new MetadataService('test_token', 'tool_drafts', 'test_user', 'provider')
    const draft = new Draft()
    draft.json = { Name: 'Test Record' }
    metadataService.saveDraft(draft).then((result) => {
      expect(result.apiId).toEqual(12)
    })
  })

  test('update draft', async () => {
    const metadataService = new MetadataService('test_token', 'tool_drafts', 'test_user', 'provider')
    const draft = new Draft()
    draft.apiId = 55
    draft.apiUserId = 10
    draft.json = { Name: 'Test Record' }
    metadataService.updateDraft(draft).then((result) => {
      expect(result.apiId).toEqual(55)
    })
    draft.apiId = 200
    metadataService.updateDraft(draft).then((result) => {
      console.log(result)
    }).catch((error) => {
      expect(error.message).toEqual('Error code: 404')
    })
  })

  test('fetch cmr keywords', async () => {
    const metadataService = new MetadataService('test_token', 'tool_drafts', 'test_user', 'provider')
    metadataService.fetchCmrKeywords('science_keywords').then((keywords) => {
      expect(keywords).toEqual({
        Name: 'a name', LongName: 'a long name', Version: '1', Type: 'Web Portal'
      })
    })
    metadataService.fetchCmrKeywords('science').then((keywords) => {
      console.log(keywords)
    }).catch((error) => {
      expect(error.message).toEqual('Error code: 404')
    })
  })
})