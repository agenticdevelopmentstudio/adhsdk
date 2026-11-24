from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ShiprRunsResponse202")


@_attrs_define
class PostV1ShiprRunsResponse202:
    """
    Attributes:
        run_id (str):
        object_ (Literal['shipr.run'] | Unset):
    """

    run_id: str
    object_: Literal["shipr.run"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        run_id = self.run_id

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "run_id": run_id,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        run_id = d.pop("run_id")

        object_ = cast(Literal["shipr.run"] | Unset, d.pop("object", UNSET))
        if object_ != "shipr.run" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'shipr.run', got '{object_}'")

        post_v1_shipr_runs_response_202 = cls(
            run_id=run_id,
            object_=object_,
        )

        post_v1_shipr_runs_response_202.additional_properties = d
        return post_v1_shipr_runs_response_202

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
