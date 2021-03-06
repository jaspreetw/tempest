# Copyright 2012 NTT Data
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import json

from tempest.api_schema.response.compute.v2_1\
    import quota_classes as classes_schema
from tempest.common import service_client


class QuotaClassesClientJSON(service_client.ServiceClient):

    def show_quota_class_set(self, quota_class_id):
        """List the quota class set for a quota class."""

        url = 'os-quota-class-sets/%s' % quota_class_id
        resp, body = self.get(url)
        body = json.loads(body)
        self.validate_response(classes_schema.get_quota_class_set, resp, body)
        return service_client.ResponseBody(resp, body['quota_class_set'])

    def update_quota_class_set(self, quota_class_id, **kwargs):
        """
        Updates the quota class's limits for one or more resources.
        """
        post_body = json.dumps({'quota_class_set': kwargs})

        resp, body = self.put('os-quota-class-sets/%s' % quota_class_id,
                              post_body)

        body = json.loads(body)
        self.validate_response(classes_schema.update_quota_class_set,
                               resp, body)
        return service_client.ResponseBody(resp, body['quota_class_set'])
