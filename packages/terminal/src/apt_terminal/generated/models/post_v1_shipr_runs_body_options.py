from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ShiprRunsBodyOptions")


@_attrs_define
class PostV1ShiprRunsBodyOptions:
    """Per-operation arguments. Read defensively; unknown keys are ignored.

    Attributes:
        sha (str | Unset): prepare: the tip to pin. Absent means the dev repo’s main as it stands.
        shard (str | Unset): register: which [deployments] key this mirror is.
        group_id (str | Unset): register: the folder a FIRST registration files its new mirrors under.
    """

    sha: str | Unset = UNSET
    shard: str | Unset = UNSET
    group_id: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        sha = self.sha

        shard = self.shard

        group_id = self.group_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if sha is not UNSET:
            field_dict["sha"] = sha
        if shard is not UNSET:
            field_dict["shard"] = shard
        if group_id is not UNSET:
            field_dict["group_id"] = group_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        sha = d.pop("sha", UNSET)

        shard = d.pop("shard", UNSET)

        group_id = d.pop("group_id", UNSET)

        post_v1_shipr_runs_body_options = cls(
            sha=sha,
            shard=shard,
            group_id=group_id,
        )

        post_v1_shipr_runs_body_options.additional_properties = d
        return post_v1_shipr_runs_body_options

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
