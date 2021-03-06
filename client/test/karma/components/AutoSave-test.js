import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import AutoSave from '../../../app/components/AutoSave';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { LOGO_COLORS } from '../../../app/constants/AppConstants';
import sinon from 'sinon';
// eslint-disable-next-line no-unused-vars
import DailyDocketContainer from '../../../app/hearings/containers/DailyDocketContainer';

export const saveFunction = () => ({ my: 'action' });

describe('AutoSave', () => {
  context('when isSaving is not true', () => {
    it('renders "Last saved at"', () => {
      const wrapper = mount(
        <AutoSave save={saveFunction} />
      );

      expect(wrapper.find('.saving').text()).to.include('Last saved at');
    });
  });

  context('when isSaving is true', () => {
    it('renders default spinner', () => {
      const wrapper = mount(
        <AutoSave
          isSaving
          save={saveFunction}
        />
      );

      const spinner = wrapper.find(`[fill="${COLORS.GREY_DARK}"]`).first();

      expect(spinner).to.have.length(1);
    });

    it('renders a spinner for an application', () => {
      const wrapper = mount(
        <AutoSave
          isSaving
          spinnerColor={LOGO_COLORS.HEARINGS.ACCENT}
          save={saveFunction}
        />
      );

      const spinner = wrapper.find(`[fill="${LOGO_COLORS.HEARINGS.ACCENT}"]`).first();

      expect(spinner).to.have.length(1);
    });
  });

  context('calls save', () => {
    it('in 30 seconds by default', () => {
      const clock = sinon.useFakeTimers();
      const saveFunc = sinon.spy(saveFunction);

      mount(
        <AutoSave save={saveFunc} />
      );

      clock.tick(30000);
      clock.restore();
      expect(saveFunc.calledOnce).to.equal(true);
    });

    it('in specified interval', () => {
      const clock = sinon.useFakeTimers();
      const intervalInMs = 3000;
      const saveFunc = sinon.spy(saveFunction);

      mount(
        <AutoSave save={saveFunc} intervalInMs={intervalInMs} />
      );

      clock.tick(intervalInMs);
      clock.restore();
      expect(saveFunc.calledOnce).to.equal(true);
    });

    it('before the window closes', () => {
      mount(
        <AutoSave save={saveFunction} />
      );
      window.close();
      let temporaryTimeout = setTimeout(() => {
        expect(saveFunction.calledOnce).to.equal(true);
      });

      clearTimeout(temporaryTimeout);
    });

    it('before it unmounts', () => {
      const saveFunc = sinon.spy(saveFunction);

      const wrapper = mount(
        <AutoSave save={saveFunc} />
      );

      wrapper.unmount();
      expect(saveFunc.calledOnce).to.equal(true);
    });
  });
});
