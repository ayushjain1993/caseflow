// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { css } from 'glamor';

import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';

import { COLORS, ISSUE_DISPOSITIONS } from '../constants';
import COPY from '../../../COPY.json';
import VACOLS_DISPOSITIONS_BY_ID from '../../../constants/VACOLS_DISPOSITIONS_BY_ID.json';

import type {
  Appeal,
  Issue
} from '../types/models';

type Params = {|
  updateIssue: Function,
  appeal: Appeal,
  issue: Issue
|};

type Props = Params & {|
  highlight: boolean
|}

class SelectIssueDispositionDropdown extends React.PureComponent<Props> {
  getStyling = () => {
    const {
      highlight,
      issue: { disposition }
    } = this.props;

    if (highlight && !disposition) {
      return css({
        borderLeft: `4px solid ${COLORS.ERROR}`,
        paddingLeft: '1rem',
        minHeight: '8rem'
      });
    }

    return css({ minHeight: '12rem' });
  }

  render = () => {
    const {
      appeal,
      highlight,
      issue
    } = this.props;

    return <div className="issue-disposition-dropdown"{...this.getStyling()}>
      <SearchableDropdown
        placeholder="Select Disposition"
        value={issue.disposition}
        hideLabel
        errorMessage={(highlight && !issue.disposition) ? COPY.FORM_ERROR_FIELD_REQUIRED : ''}
        options={Object.entries(VACOLS_DISPOSITIONS_BY_ID).slice(0, 6).
          map((opt) => ({
            label: `${opt[0]} - ${String(opt[1])}`,
            value: opt[0]
          }))}
        onChange={(option) => this.props.updateIssue({
          disposition: option ? option.value : null,
          readjudication: false,
          remand_reasons: []
        })}
        name={`dispositions_dropdown_${String(issue.id)}`} />
      {appeal.isLegacyAppeal && issue.disposition === ISSUE_DISPOSITIONS.VACATED && <Checkbox
        name={`duplicate-vacated-issue-${String(issue.id)}`}
        styling={css({
          marginBottom: 0,
          marginTop: '1rem'
        })}
        onChange={(readjudication) => this.props.updateIssue({ readjudication })}
        value={issue.readjudication}
        label="Automatically create vacated issue for readjudication." />}
    </div>;
  };
}

const mapStateToProps = (state) => ({
  highlight: state.ui.highlightFormItems
});

export default (connect(mapStateToProps)(SelectIssueDispositionDropdown): React.ComponentType<Params>);
