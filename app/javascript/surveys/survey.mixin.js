import {mapGetters} from 'vuex';
import toastMixin from '../shared/toast-mixin';
import { SAVE, SELECT, SELECTED, FETCH_SELECTED, DELETE, UNSELECT } from '../store/model.store';
import { SURVEY_SAVE_SUCCESS, SURVEY_SAVE_SUCCESS_DELETE } from '../constants/strings'
import { surveyModel as model} from '@/store/survey';
import { getOrderedRelationships } from '../utils/jsonapi_utils';

// CONVERTED
export const surveyMixin = {
  mixins: [toastMixin],
  computed: {
    ...mapGetters({
      selected: SELECTED
    }),
    survey() {
      return this.selected({model});
    },
    selectedSurveyPages() {
      if (!this.survey) return []
      return this.getSurveyPages(this.survey)
    },
    selectedSurveyFirstPage() {
      return this.survey && this.selectedSurveyPages[0];

    },
  },
  methods: {
    saveSurvey(newSurvey, success_text = SURVEY_SAVE_SUCCESS) {
      if (!newSurvey) {
        newSurvey = this.survey;
      }
      return this.toastPromise(this.$store.dispatch(SAVE, {model, selected: true, item: newSurvey}), success_text)
    },
    selectSurvey(itemOrId) {
      this.$store.commit(SELECT, {model, itemOrId});
    },
    unselectSurvey() {
      this.$store.commit(UNSELECT, {model})
    },
    fetchSelectedSurvey() {
      return this.$store.dispatch(FETCH_SELECTED, {model});
    },
    deleteSurvey(itemOrId, success_text = SURVEY_SAVE_SUCCESS_DELETE) {
      if (!itemOrId) {
        itemOrId = this.survey;
      }
      return this.toastPromise(this.$store.dispatch(DELETE, {model, itemOrId}), success_text);
    },
    getSurveyPages(survey) {
      return getOrderedRelationships('pages', survey);
    }
  }
}

export default surveyMixin;
