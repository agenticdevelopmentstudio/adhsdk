from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.invite_preview_state import InvitePreviewState
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1InvitationsPreviewResponse200")


@_attrs_define
class GetV1InvitationsPreviewResponse200:
    """
    Attributes:
        state (InvitePreviewState):
        ecosystem_name (None | str | Unset):
        masked_destination (None | str | Unset):
        object_ (Literal['invitation'] | Unset):
    """

    state: InvitePreviewState
    ecosystem_name: None | str | Unset = UNSET
    masked_destination: None | str | Unset = UNSET
    object_: Literal["invitation"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        state = self.state.value

        ecosystem_name: None | str | Unset
        if isinstance(self.ecosystem_name, Unset):
            ecosystem_name = UNSET
        else:
            ecosystem_name = self.ecosystem_name

        masked_destination: None | str | Unset
        if isinstance(self.masked_destination, Unset):
            masked_destination = UNSET
        else:
            masked_destination = self.masked_destination

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "state": state,
            }
        )
        if ecosystem_name is not UNSET:
            field_dict["ecosystem_name"] = ecosystem_name
        if masked_destination is not UNSET:
            field_dict["masked_destination"] = masked_destination
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        state = InvitePreviewState(d.pop("state"))

        def _parse_ecosystem_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        ecosystem_name = _parse_ecosystem_name(d.pop("ecosystem_name", UNSET))

        def _parse_masked_destination(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        masked_destination = _parse_masked_destination(d.pop("masked_destination", UNSET))

        object_ = cast(Literal["invitation"] | Unset, d.pop("object", UNSET))
        if object_ != "invitation" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'invitation', got '{object_}'")

        get_v1_invitations_preview_response_200 = cls(
            state=state,
            ecosystem_name=ecosystem_name,
            masked_destination=masked_destination,
            object_=object_,
        )

        get_v1_invitations_preview_response_200.additional_properties = d
        return get_v1_invitations_preview_response_200

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
