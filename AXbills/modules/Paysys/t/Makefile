#make test all payments systems

PERL						=	/usr/bin/perl
AVAILABLE_PAYMENT_SYSTEMS	=	$(shell find ../systems/ -name '*.pm' | xargs -n 1 basename | cut -f 1 -d '.')
AVAILABLE_TEST				=	$(shell find ./ -name '*.t' | xargs -n 1 basename)
TEST_LIST					=	$(foreach available_test, $(AVAILABLE_TEST), $(foreach test_list, $(foreach payments_system, $(AVAILABLE_PAYMENT_SYSTEMS), $(payments_system).t), $(if $(filter $(available_test), $(test_list)), $(available_test), )))

define run_test_exist_user

	$(PERL) ${1}

endef

define run_test_not_exist_user

	$(PERL) ${1} user=99999999999999999999999999

endef


run_all_tests:

	$(foreach test, $(TEST_LIST), $(call run_test_exist_user, $(test))) \
	$(foreach test, $(TEST_LIST), $(call run_test_not_exist_user, $(test)))