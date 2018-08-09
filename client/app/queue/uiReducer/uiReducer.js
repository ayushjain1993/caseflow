// @flow
import { update } from '../../util/ReducerUtil';
import { ACTIONS } from './uiConstants';
import { ACTIONS as QUEUE_ACTIONS } from '../constants';
import type { UiState } from '../types/state';

const initialSaveState = {
  savePending: false,
  saveSuccessful: null
};

export const initialState = {
  selectingJudge: false,
  highlightFormItems: false,
  messages: {
    success: null,
    error: null
  },
  saveState: initialSaveState,
  modal: {},
  featureToggles: {},
  userRole: '',
  userCssId: '',
  loadedUserId: null,
  selectedAssignee: null,
  selectedAssigneeSecondary: null,
  veteranCaseListIsVisible: false
};

const setMessageState = (state, message, msgType) => update(state, {
  messages: {
    [msgType]: {
      $set: message
    }
  }
});

const setErrorMessageState = (state, message) => setMessageState(state, message, 'error');
const hideErrorMessage = (state) => setErrorMessageState(state, null);
const showErrorMessage = (state, errorMsg = { title: 'Error' }) => setErrorMessageState(state, errorMsg);

const setSuccessMessageState = (state, message) => setMessageState(state, message, 'success');
const hideSuccessMessage = (state) => setSuccessMessageState(state, null);
const showSuccessMessage = (state, message = { title: 'Success' }) => setSuccessMessageState(state, message);

const setModalState = (state, visibility, modalType) => update(state, {
  modal: {
    [modalType]: {
      $set: visibility
    }
  }
});

const showModal = (state, modalType) => setModalState(state, true, modalType);
const hideModal = (state, modalType) => setModalState(state, false, modalType);

const workQueueUiReducer = (state: UiState = initialState, action: Object = {}) => {
  switch (action.type) {
  case ACTIONS.SET_SELECTING_JUDGE:
    return update(state, {
      selectingJudge: { $set: action.payload.selectingJudge }
    });
  case ACTIONS.HIGHLIGHT_INVALID_FORM_ITEMS:
    return update(state, {
      highlightFormItems: {
        $set: action.payload.highlight
      }
    });
  case ACTIONS.REQUEST_SAVE:
    return update(state, {
      saveState: {
        savePending: { $set: true },
        saveSuccessful: { $set: null }
      }
    });
  case ACTIONS.SAVE_SUCCESS:
    return update(state, {
      saveState: {
        savePending: { $set: false },
        saveSuccessful: { $set: true }
      }
    });
  case ACTIONS.SAVE_FAILURE:
    return update(state, {
      saveState: {
        savePending: { $set: false },
        saveSuccessful: { $set: false }
      }
    });
  case ACTIONS.RESET_SAVE_STATE:
    return update(state, {
      saveState: { $set: initialSaveState }
    });
  case ACTIONS.RESET_ERROR_MESSAGES:
    return update(state, {
      messages: {
        error: { $set: null }
      }
    });
  case ACTIONS.RESET_SUCCESS_MESSAGES:
    return update(state, {
      messages: {
        success: { $set: null }
      }
    });
  case ACTIONS.HIDE_ERROR_MESSAGE:
    return hideErrorMessage(state);
  case ACTIONS.SHOW_ERROR_MESSAGE:
    return showErrorMessage(state, action.payload.errorMessage);
  case ACTIONS.SHOW_SUCCESS_MESSAGE:
    return showSuccessMessage(state, action.payload.message);
  case ACTIONS.HIDE_SUCCESS_MESSAGE:
    return hideSuccessMessage(state);
  case ACTIONS.SHOW_MODAL:
    return showModal(state, action.payload.modalType);
  case ACTIONS.HIDE_MODAL:
    return hideModal(state, action.payload.modalType);
  case ACTIONS.SET_FEATURE_TOGGLES:
    return update(state, {
      featureToggles: {
        $set: action.payload.featureToggles
      }
    });
  case ACTIONS.TOGGLE_VETERAN_CASE_LIST:
    return update(state, {
      veteranCaseListIsVisible: { $set: !state.veteranCaseListIsVisible }
    });
  case ACTIONS.HIDE_VETERAN_CASE_LIST:
    return update(state, {
      veteranCaseListIsVisible: { $set: false }
    });
  case QUEUE_ACTIONS.RECEIVE_QUEUE_DETAILS:
    return update(state, {
      loadedUserId: { $set: action.payload.userId }
    });
  case ACTIONS.SET_USER_ROLE:
    return update(state, {
      userRole: { $set: action.payload.userRole }
    });
  case ACTIONS.SET_USER_CSS_ID:
    return update(state, {
      userCssId: { $set: action.payload.cssId }
    });
  case ACTIONS.SET_SELECTED_ASSIGNEE:
    return update(state, {
      selectedAssignee: {
        $set: action.payload.assigneeId
      }
    });
  case ACTIONS.SET_SELECTED_ASSIGNEE_SECONDARY:
    return update(state, {
      selectedAssigneeSecondary: {
        $set: action.payload.assigneeId
      }
    });
  default:
    return state;
  }
};

export default workQueueUiReducer;
