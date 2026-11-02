from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="GetCommunitiesIdMembersMeResponse200")


@_attrs_define
class GetCommunitiesIdMembersMeResponse200:
    """
    Attributes:
        role (None | str): owner | admin | moderator | member, or null (not a member).
    """

    role: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        role: None | str
        role = self.role

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "role": role,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)

        def _parse_role(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        role = _parse_role(d.pop("role"))

        get_communities_id_members_me_response_200 = cls(
            role=role,
        )

        get_communities_id_members_me_response_200.additional_properties = d
        return get_communities_id_members_me_response_200

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
