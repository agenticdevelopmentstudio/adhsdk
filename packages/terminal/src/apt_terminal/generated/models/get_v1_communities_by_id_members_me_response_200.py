from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1CommunitiesByIdMembersMeResponse200")


@_attrs_define
class GetV1CommunitiesByIdMembersMeResponse200:
    """
    Attributes:
        role (None | str): owner | admin | moderator | member, or null (not a member).
        object_ (Literal['member'] | Unset):
    """

    role: None | str
    object_: Literal["member"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        role: None | str
        role = self.role

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "role": role,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)

        def _parse_role(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        role = _parse_role(d.pop("role"))

        object_ = cast(Literal["member"] | Unset, d.pop("object", UNSET))
        if object_ != "member" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'member', got '{object_}'")

        get_v1_communities_by_id_members_me_response_200 = cls(
            role=role,
            object_=object_,
        )

        get_v1_communities_by_id_members_me_response_200.additional_properties = d
        return get_v1_communities_by_id_members_me_response_200

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
