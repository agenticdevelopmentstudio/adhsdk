from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.registry_persona_approval_status import RegistryPersonaApprovalStatus
from ..models.registry_persona_approval_subject_kind import RegistryPersonaApprovalSubjectKind
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.registry_persona_approval_args import RegistryPersonaApprovalArgs
    from ..models.registry_persona_approval_result_type_0 import RegistryPersonaApprovalResultType0


T = TypeVar("T", bound="GetV1ProcessingPersonaApprovalsResponse200DataItem")


@_attrs_define
class GetV1ProcessingPersonaApprovalsResponse200DataItem:
    """
    Attributes:
        id (str):
        persona_id (str):
        subject_kind (RegistryPersonaApprovalSubjectKind):
        subject_eco (str):
        tool_name (str): curated tool name, or the gateway tool 'adh_request'
        args (RegistryPersonaApprovalArgs): the frozen invocation payload
        status (RegistryPersonaApprovalStatus):
        created (int): Unix timestamp, in seconds.
        subject_id (None | str | Unset): null for self/eco-scoped subjects
        requested_by (None | str | Unset):
        decided_by (None | str | Unset): the human who decided (null until then)
        decided_at (None | str | Unset):
        result (None | RegistryPersonaApprovalResultType0 | Unset): the outcome once an approved action runs (null until
            then)
        object_ (Literal['processing.persona_approval'] | Unset):
    """

    id: str
    persona_id: str
    subject_kind: RegistryPersonaApprovalSubjectKind
    subject_eco: str
    tool_name: str
    args: RegistryPersonaApprovalArgs
    status: RegistryPersonaApprovalStatus
    created: int
    subject_id: None | str | Unset = UNSET
    requested_by: None | str | Unset = UNSET
    decided_by: None | str | Unset = UNSET
    decided_at: None | str | Unset = UNSET
    result: None | RegistryPersonaApprovalResultType0 | Unset = UNSET
    object_: Literal["processing.persona_approval"] | Unset = UNSET
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

        created = self.created

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

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "persona_id": persona_id,
                "subject_kind": subject_kind,
                "subject_eco": subject_eco,
                "tool_name": tool_name,
                "args": args,
                "status": status,
                "created": created,
            }
        )
        if subject_id is not UNSET:
            field_dict["subject_id"] = subject_id
        if requested_by is not UNSET:
            field_dict["requested_by"] = requested_by
        if decided_by is not UNSET:
            field_dict["decided_by"] = decided_by
        if decided_at is not UNSET:
            field_dict["decided_at"] = decided_at
        if result is not UNSET:
            field_dict["result"] = result
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        persona_id = d.pop("persona_id")

        subject_kind = RegistryPersonaApprovalSubjectKind(d.pop("subject_kind"))

        subject_eco = d.pop("subject_eco")

        tool_name = d.pop("tool_name")

        args = RegistryPersonaApprovalArgs.from_dict(d.pop("args"))

        status = RegistryPersonaApprovalStatus(d.pop("status"))

        created = d.pop("created")

        def _parse_subject_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        subject_id = _parse_subject_id(d.pop("subject_id", UNSET))

        def _parse_requested_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        requested_by = _parse_requested_by(d.pop("requested_by", UNSET))

        def _parse_decided_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        decided_by = _parse_decided_by(d.pop("decided_by", UNSET))

        def _parse_decided_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        decided_at = _parse_decided_at(d.pop("decided_at", UNSET))

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

        object_ = cast(Literal["processing.persona_approval"] | Unset, d.pop("object", UNSET))
        if object_ != "processing.persona_approval" and not isinstance(object_, Unset):
            raise ValueError(
                f"object must match const 'processing.persona_approval', got '{object_}'"
            )

        get_v1_processing_persona_approvals_response_200_data_item = cls(
            id=id,
            persona_id=persona_id,
            subject_kind=subject_kind,
            subject_eco=subject_eco,
            tool_name=tool_name,
            args=args,
            status=status,
            created=created,
            subject_id=subject_id,
            requested_by=requested_by,
            decided_by=decided_by,
            decided_at=decided_at,
            result=result,
            object_=object_,
        )

        get_v1_processing_persona_approvals_response_200_data_item.additional_properties = d
        return get_v1_processing_persona_approvals_response_200_data_item

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
