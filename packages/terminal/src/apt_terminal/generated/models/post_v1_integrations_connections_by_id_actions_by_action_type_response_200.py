from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.integration_me_action_result_status import IntegrationMeActionResultStatus
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1IntegrationsConnectionsByIdActionsByActionTypeResponse200")


@_attrs_define
class PostV1IntegrationsConnectionsByIdActionsByActionTypeResponse200:
    """
    Attributes:
        ok (bool):
        status (IntegrationMeActionResultStatus):
        action_log_id (str):
        external_id (None | str):
        deduped (bool):
        error (str | Unset):
        result (Any | Unset): The action's raw result, when it returned one.
        object_ (Literal['action'] | Unset):
    """

    ok: bool
    status: IntegrationMeActionResultStatus
    action_log_id: str
    external_id: None | str
    deduped: bool
    error: str | Unset = UNSET
    result: Any | Unset = UNSET
    object_: Literal["action"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ok = self.ok

        status = self.status.value

        action_log_id = self.action_log_id

        external_id: None | str
        external_id = self.external_id

        deduped = self.deduped

        error = self.error

        result = self.result

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ok": ok,
                "status": status,
                "action_log_id": action_log_id,
                "external_id": external_id,
                "deduped": deduped,
            }
        )
        if error is not UNSET:
            field_dict["error"] = error
        if result is not UNSET:
            field_dict["result"] = result
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ok = d.pop("ok")

        status = IntegrationMeActionResultStatus(d.pop("status"))

        action_log_id = d.pop("action_log_id")

        def _parse_external_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        external_id = _parse_external_id(d.pop("external_id"))

        deduped = d.pop("deduped")

        error = d.pop("error", UNSET)

        result = d.pop("result", UNSET)

        object_ = cast(Literal["action"] | Unset, d.pop("object", UNSET))
        if object_ != "action" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'action', got '{object_}'")

        post_v1_integrations_connections_by_id_actions_by_action_type_response_200 = cls(
            ok=ok,
            status=status,
            action_log_id=action_log_id,
            external_id=external_id,
            deduped=deduped,
            error=error,
            result=result,
            object_=object_,
        )

        post_v1_integrations_connections_by_id_actions_by_action_type_response_200.additional_properties = d
        return post_v1_integrations_connections_by_id_actions_by_action_type_response_200

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
