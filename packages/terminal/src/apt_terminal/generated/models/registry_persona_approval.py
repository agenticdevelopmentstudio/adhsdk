from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.registry_persona_approval_status import RegistryPersonaApprovalStatus
from ..models.registry_persona_approval_subject_kind import RegistryPersonaApprovalSubjectKind
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.registry_persona_approval_args import RegistryPersonaApprovalArgs
    from ..models.registry_persona_approval_result_type_0 import RegistryPersonaApprovalResultType0


T = TypeVar("T", bound="RegistryPersonaApproval")


@_attrs_define
class RegistryPersonaApproval:
    """
    Attributes:
        id (str):
        persona_id (str):
        subject_kind (RegistryPersonaApprovalSubjectKind):
        subject_eco (str):
        tool_name (str): curated tool name, or the gateway tool 'adh_request'
        args (RegistryPersonaApprovalArgs): the frozen invocation payload
        status (RegistryPersonaApprovalStatus):
        created_at (str):
        subject_id (None | str | Unset): null for self/eco-scoped subjects
        requested_by (None | str | Unset):
        decided_by (None | str | Unset): the human who decided (null until then)
        decided_at (None | str | Unset):
        result (None | RegistryPersonaApprovalResultType0 | Unset): the outcome once an approved action runs (null until
            then)
    """

    id: str
    persona_id: str
    subject_kind: RegistryPersonaApprovalSubjectKind
    subject_eco: str
    tool_name: str
    args: RegistryPersonaApprovalArgs
    status: RegistryPersonaApprovalStatus
    created_at: str
    subject_id: None | str | Unset = UNSET
    requested_by: None | str | Unset = UNSET
    decided_by: None | str | Unset = UNSET
    decided_at: None | str | Unset = UNSET
    result: None | RegistryPersonaApprovalResultType0 | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.registry_persona_approval_result_type_0 import (
            RegistryPersonaApprovalResultType0,
        )

        id = self.id

        persona_id = self.persona_id

        subject_kind = self.subject_kind.value

        subject_eco = self.subject_eco

        tool_name = self.tool_name

        args = self.args.to_dict()

        status = self.status.value

        created_at = self.created_at

        subject_id: None | str | Unset
        if isinstance(self.subject_id, Unset):
            subject_id = UNSET
        else:
            subject_id = self.subject_id

        requested_by: None | str | Unset
        if isinstance(self.requested_by, Unset):
            requested_by = UNSET
        else:
            requested_by = self.requested_by

        decided_by: None | str | Unset
        if isinstance(self.decided_by, Unset):
            decided_by = UNSET
        else:
            decided_by = self.decided_by

        decided_at: None | str | Unset
        if isinstance(self.decided_at, Unset):
            decided_at = UNSET
        else:
            decided_at = self.decided_at

        result: dict[str, Any] | None | Unset
        if isinstance(self.result, Unset):
            result = UNSET
        elif isinstance(self.result, RegistryPersonaApprovalResultType0):
            result = self.result.to_dict()
        else:
            result = self.result

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "personaId": persona_id,
                "subjectKind": subject_kind,
                "subjectEco": subject_eco,
                "toolName": tool_name,
                "args": args,
                "status": status,
                "createdAt": created_at,
            }
        )
        if subject_id is not UNSET:
            field_dict["subjectId"] = subject_id
        if requested_by is not UNSET:
            field_dict["requestedBy"] = requested_by
        if decided_by is not UNSET:
            field_dict["decidedBy"] = decided_by
        if decided_at is not UNSET:
            field_dict["decidedAt"] = decided_at
        if result is not UNSET:
            field_dict["result"] = result

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.registry_persona_approval_args import (
            RegistryPersonaApprovalArgs,
        )
        from ..models.registry_persona_approval_result_type_0 import (
            RegistryPersonaApprovalResultType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        persona_id = d.pop("personaId")

        subject_kind = RegistryPersonaApprovalSubjectKind(d.pop("subjectKind"))

        subject_eco = d.pop("subjectEco")

        tool_name = d.pop("toolName")

        args = RegistryPersonaApprovalArgs.from_dict(d.pop("args"))

        status = RegistryPersonaApprovalStatus(d.pop("status"))

        created_at = d.pop("createdAt")

        def _parse_subject_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        subject_id = _parse_subject_id(d.pop("subjectId", UNSET))

        def _parse_requested_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        requested_by = _parse_requested_by(d.pop("requestedBy", UNSET))

        def _parse_decided_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        decided_by = _parse_decided_by(d.pop("decidedBy", UNSET))

        def _parse_decided_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        decided_at = _parse_decided_at(d.pop("decidedAt", UNSET))

        def _parse_result(data: object) -> None | RegistryPersonaApprovalResultType0 | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                result_type_0 = RegistryPersonaApprovalResultType0.from_dict(data)

                return result_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | RegistryPersonaApprovalResultType0 | Unset, data)

        result = _parse_result(d.pop("result", UNSET))

        registry_persona_approval = cls(
            id=id,
            persona_id=persona_id,
            subject_kind=subject_kind,
            subject_eco=subject_eco,
            tool_name=tool_name,
            args=args,
            status=status,
            created_at=created_at,
            subject_id=subject_id,
            requested_by=requested_by,
            decided_by=decided_by,
            decided_at=decided_at,
            result=result,
        )

        registry_persona_approval.additional_properties = d
        return registry_persona_approval

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
