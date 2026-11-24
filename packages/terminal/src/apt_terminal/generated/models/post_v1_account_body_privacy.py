from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_account_body_privacy_target_table import PostV1AccountBodyPrivacyTargetTable

T = TypeVar("T", bound="PostV1AccountBodyPrivacy")


@_attrs_define
class PostV1AccountBodyPrivacy:
    """Updates `privacy`.

    Attributes:
        target_table (PostV1AccountBodyPrivacyTargetTable):
        target_id (str):
        audience_mask (int): Bitmask of audiences: 1=PUBLIC, 2=HUB (or their OR, 3). 0 = only-me. TEAM/ORG/AI bits are
            rejected with 400.
    """

    target_table: PostV1AccountBodyPrivacyTargetTable
    target_id: str
    audience_mask: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        target_table = self.target_table.value

        target_id = self.target_id

        audience_mask = self.audience_mask

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "target_table": target_table,
                "target_id": target_id,
                "audience_mask": audience_mask,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        target_table = PostV1AccountBodyPrivacyTargetTable(d.pop("target_table"))

        target_id = d.pop("target_id")

        audience_mask = d.pop("audience_mask")

        post_v1_account_body_privacy = cls(
            target_table=target_table,
            target_id=target_id,
            audience_mask=audience_mask,
        )

        post_v1_account_body_privacy.additional_properties = d
        return post_v1_account_body_privacy

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
