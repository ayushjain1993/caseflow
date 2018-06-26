// @flow
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import StatusMessage from '../components/StatusMessage';
import JudgeAssignTaskTable from './JudgeAssignTaskTable';
import SmallLoader from '../components/SmallLoader';
import { LOGO_COLORS } from '../constants/AppConstants';
import { setSelectionOfTaskOfUser } from './QueueActions';
import { sortTasks } from './utils';
import type { State, Tasks, AttorneysOfJudge, TasksAndAppealsOfAttorney } from './reducers';
import _ from 'lodash';

const AssignedCasesPage = (props: {|
  tasksAndAppealsOfAttorney: TasksAndAppealsOfAttorney,
  attorneysOfJudge: AttorneysOfJudge,
  tasks: Tasks,
  match: {params: {attorneyId: string}}
|}) => {
  const {
    match, attorneysOfJudge, tasksAndAppealsOfAttorney, tasks
  } = props;
  const { attorneyId } = match.params;

  if (!(attorneyId in tasksAndAppealsOfAttorney) || tasksAndAppealsOfAttorney[attorneyId].state === 'LOADING') {
    return <SmallLoader message="Loading..." spinnerColor={LOGO_COLORS.QUEUE.ACCENT} />;
  }

  if (tasksAndAppealsOfAttorney[attorneyId].state === 'FAILED') {
    const { error } = tasksAndAppealsOfAttorney[attorneyId];

    if (!error.response) {
      return <StatusMessage title="Timeout">Error fetching cases</StatusMessage>;
    }

    return <StatusMessage title={error.response.statusText}>Error fetching cases</StatusMessage>;
  }

  const attorneyName = attorneysOfJudge.filter((attorney) => attorney.id.toString() === attorneyId)[0].full_name;
  const { tasks: taskIdsOfAttorney, appeals } = tasksAndAppealsOfAttorney[attorneyId].data;
  const tasksOfAttorney = {};

  for (const taskId of Object.keys(taskIdsOfAttorney)) {
    tasksOfAttorney[taskId] = tasks[taskId];
  }

  return <React.Fragment>
    <h2>{attorneyName}'s Cases</h2>
    <JudgeAssignTaskTable
      tasksAndAppeals={
        sortTasks({
          tasks: tasksOfAttorney,
          appeals
        }).
          map((task) => ({
            task,
            appeal: appeals[task.vacolsId] }))
      }
      userId={attorneyId} />
  </React.Fragment>;
};

const mapStateToProps = (state) => {
  return _.pick(state.queue, 'tasksAndAppealsOfAttorney', 'attorneysOfJudge');
};

export default connect(
  mapStateToProps,
  (dispatch) => (bindActionCreators({ setSelectionOfTaskOfUser }, dispatch)))(AssignedCasesPage);
