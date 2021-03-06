import computed from 'ember-addons/ember-computed-decorators';

export default Ember.Controller.extend({
  showTop: true,
  showFooter: false,

  @computed
  canSignUp() {
    return !Discourse.SiteSettings.invite_only &&
           Discourse.SiteSettings.allow_new_registrations &&
           !Discourse.SiteSettings.enable_sso;
  },

  @computed
  loginRequired() {
    return Discourse.SiteSettings.login_required && !Discourse.User.current();
  },

  actions: {
    appRouteAction(name) {
      return this.send(name);
    },

    appRouteParameterizedAction(name, param) {
      return this.send(name, param);
    }
  }
});
