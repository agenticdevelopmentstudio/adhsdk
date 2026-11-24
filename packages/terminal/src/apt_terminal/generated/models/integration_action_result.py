from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.integration_action_result_status import IntegrationActionResultStatus
from ..types import UNSET, Unset

T = TypeVar("T", bound="IntegrationActionResult")


@_attrs_define
class IntegrationActionResult:
    """
    Attributes:
        ok (bool): true when status is ok
        status (IntegrationActionResultStatus):
        action_log_id (str): The integration_action_logs row id
        external_id (None | str): Provider-side id produced, if any
        deduped (bool): true when an Idempotency-Key replay returned a prior row
        error (str | Unset): Failure message when status is error
    """

    ok: bool
    status: IntegrationActionResultStatus
    action_log_id: str
    external_id: None | str
    deduped: bool
    error: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ok = self.ok

        status = self.status.value

        action_log_id = self.action_log_id

        external_id: None | str
        external_id = self.external_id

        deduped = self.deduped

        error = self.error

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

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ok = d.pop("ok")

        status = IntegrationActionResultStatus(d.pop("status"))

        action_log_id = d.pop("action_log_id")

        def _parse_external_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        external_id = _parse_external_id(d.pop("external_id"))

        deduped = d.pop("deduped")

        error = d.pop("error", UNSET)

        integration_action_result = cls(
            ok=ok,
            status=status,
            action_log_id=action_log_id,
            external_id=external_id,
            deduped=deduped,
            error=error,
        )

        integration_action_result.additional_properties = d
        return integration_action_result

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
